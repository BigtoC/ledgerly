# Extended Multi-Currency Conversion — Design Spec

**Date:** 2026-05-14 (revised 2026-05-15 after document review)
**Status:** Draft (post-review)
**PRD reference:** `PRD.md` § Phased Roadmap — Phase 2: "Extended multi-currency — fetch currency prices and auto-convert balances, summaries, and charts to the user's default currency"

---

## Summary

Fetch live exchange rates from a hosted API on app startup, persist them as integer fractions in the local Drift DB, and display auto-converted amounts in the user's default currency across Home and Accounts surfaces. Conversion is purely additive display data — original transaction amounts and account balances are never modified.

**Scope of this spec:** SummaryStrip, TransactionTile, AccountTile. Analysis surfaces (CategorySearchTile, charts) are explicitly deferred to a follow-up spec; see [Out of Scope](#out-of-scope).

---

## Prerequisites

- `dio` package must be added to `pubspec.yaml` (already listed in PRD as a Phase 2 dependency).
- Cloudflare Worker `/api/conversion` route must be added to the worker spec — see [API Dependencies](#api-dependencies).

---

## Goals

- Fetch exchange rates for all non-default currencies in a single API call on startup (non-blocking).
- Persist rates to the local DB as integer fractions for instant display on next launch.
- Display converted amounts in the user's default currency on: SummaryStrip, TransactionTile, AccountTile.
- SummaryStrip simplifies from per-currency groups to a single unified total in the default currency.
- Fetch on demand when a new currency appears mid-session (e.g., user creates an account in a new currency).
- Re-fetch automatically when the user changes their default currency in Settings.
- Cached rates are always shown, even when stale — there is no expiration UI in this iteration.

## Out of Scope

- **Analysis surfaces** (CategorySearchTile, charts) in default currency — deferred to a follow-up spec. Carrying per-transaction currency through to the search result model requires changes to `analysis_state.dart` / `analysis_controller.dart` outside this spec's scope.
- **Cross-rate chaining** — the API accepts arbitrary directional pairs, so cross-rates are unnecessary.
- **User-facing rate staleness indicators or expiration warnings** — accepted product position: never hide, always show stale. See [Rate Lifecycle](#rate-lifecycle) for the trade-off.
- **Persisting converted amounts** into transaction or account rows.
- **Worker authentication / rate-limiting** — Phase 2.1 task; the endpoint is unauthenticated for this iteration.
- **TLS certificate pinning** — relies on platform TLS; pinning deferred to Phase 2.1.

---

## API

**Endpoint:** `https://ledgerly-api.bigto-fintech.workers.dev/api/conversion?tickers={tickers}`

**Ticker format:** `{fromCurrency}{toCurrency}` in lowercase, comma-separated. Example: `hkdusd,eurusd,cnyusd`.

**Auth:** None for this iteration. A separate Phase 2.1 task adds an app-identifier header and worker-side rate limiting before the worker is published broadly.

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

### API Dependencies

The `/api/conversion` route does not yet exist in `docs/superpowers/specs/2026-05-11-ledgerly-api-cloudflare-worker-design.md`. That spec must be extended to add: ticker parsing (validate each pair against `^[a-z]{3,6}$`, cap pairs-per-request at 50), the upstream rate source, the response shape above, and worker-side caching headers. Input validation lives in the worker; the client trusts the worker.

### Privacy

The ticker payload contains only currency codes (e.g., `hkdusd,btcusd`). This matches the CLAUDE.md constraint that "Phase 2 currency-price requests send only currency pairs and conversion metadata — never memos, categories, or any other transaction text." No identifier ties a request to a specific user beyond the source IP; the currency mix itself is information, and the worker's default access logs may capture query strings. Acceptable for the unauthenticated endpoint in this iteration; the Phase 2.1 auth task should also configure log query-string scrubbing.

---

## Architecture

### Components

| Layer      | File                                                | Purpose                                                                                          |
|------------|-----------------------------------------------------|--------------------------------------------------------------------------------------------------|
| Table      | `data/database/tables/exchange_rates_table.dart`    | Drift table with integer-fraction rate columns                                                   |
| DAO        | `data/database/daos/exchange_rate_dao.dart`         | `upsertAll()`, `watchAll()`, `distinctCurrenciesAcrossAllTables()`                               |
| Service    | `data/services/exchange_rate_service.dart`          | HTTP client via Dio, calls the conversion API                                                    |
| Repository | `data/repositories/exchange_rate_repository.dart`   | Orchestrates DAO + service; derives in-memory snapshot from `dao.watchAll()`                     |
| Converter  | `core/utils/currency_converter.dart`                | Pure integer-fraction minor-unit conversion                                                      |
| Providers  | `app/providers/repository_providers.dart` (extend)  | `exchangeRateServiceProvider`, `exchangeRateRepositoryProvider`, `exchangeRatesProvider`         |
| Provider   | `features/settings/settings_providers.dart` (extend)| `defaultCurrencyProvider`                                                                        |

No domain `ExchangeRate` Freezed model — service returns anonymous records, the repository materialises a snapshot map from the DAO, and conversion consumes the integer fraction directly. The intermediate domain model added no consumer value.

### Data Flow

```
Bootstrap
  → container.read(exchangeRateRepositoryProvider)  (force instantiation)
  → DriftExchangeRateRepository constructor:
    → subscribe to dao.watchAll() → rebuild _snapshot on each emission
    → subscribe to defaultCurrencyProvider stream → refreshAll(code) on each emission

refreshAll(defaultCurrency)
  → pairs = dao.distinctCurrenciesAcrossAllTables() − {defaultCurrency}
  → service.fetchRates([(c, defaultCurrency) for c in pairs])
  → validate + convert doubles to fractions + compute inverses
  → dao.upsertAll(rows)  (single mutation path; watchAll() emits → snapshot rebuilds)

New currency mid-session (form save in non-default currency)
  → repository.fetchRate(from, defaultCurrency)
    → service.fetchRates([(from, defaultCurrency)]) → validate → dao.upsertAll(...)

Default currency change in Settings
  → defaultCurrencyProvider emits new code
  → subscription handler calls refreshAll(newDefault)

UI (any surface)
  → ref.watch(exchangeRatesProvider)  → snapshot map (triggers rebuild)
  → repo.getRate(from, to)            → integer fraction record (sync, reads _snapshot)
  → CurrencyConverter.convertMinorUnits(amount, rate.numerator, rate.denominator, fromDec, toDec)
  → MoneyFormatter.format(amountMinorUnits: ..., currency: ..., locale: ...)
```

Single source of truth: the Drift `exchange_rates` table. The in-memory `_snapshot` is a derived projection of `dao.watchAll()` — no parallel mutation path exists.

---

## Data Model

### Drift Table — `data/database/tables/exchange_rates_table.dart`

| Column            | Type     | Constraints                                                |
|-------------------|----------|------------------------------------------------------------|
| id                | INTEGER  | PRIMARY KEY AUTOINCREMENT                                  |
| base_currency     | TEXT     | NOT NULL REFERENCES currencies(code)                       |
| quote_currency    | TEXT     | NOT NULL REFERENCES currencies(code)                       |
| rate_numerator    | INTEGER  | NOT NULL                                                   |
| rate_denominator  | INTEGER  | NOT NULL, CHECK(rate_denominator > 0)                      |
| fetched_at        | DATETIME | NOT NULL                                                   |

Unique index on `(base_currency, quote_currency)` — one rate per pair. Upsert replaces on conflict.

**Why integer fractions:** CLAUDE.md → Data-Model Invariants: "Money is stored as integer minor units... Phase 2 exchange rates are stored as numerator/denominator integer fractions for the same reason." The service receives a `double` from the API, and the **repository** (not the service — the service layer can't import models) converts it to a fraction with a fixed denominator (`1_000_000_000` = 10⁹) before insert. This preserves ~9 decimal digits of precision and keeps the conversion path in 64-bit integer arithmetic (with BigInt where needed) until the final formatting step.

### API-to-fraction conversion

```dart
({int numerator, int denominator}) doubleToFraction(double rate) {
  const denom = 1000000000; // 10^9 → ~9 decimal digits of precision
  return (numerator: (rate * denom).round(), denominator: denom);
}
```

---

## API Integration — `data/services/exchange_rate_service.dart`

Injects `Dio` via constructor. Single method:

```dart
Future<List<({String from, String to, double rate, DateTime fetchedAt})>> fetchRates(
  List<({String from, String to})> pairs,
)
```

Returns raw parsed data as a record list. The `services_forbid_upstream_and_siblings` rule in `import_analysis_options.yaml` blocks `data/services/` from importing `data/models/` (and the `data/repositories/` layer above it), so the service uses anonymous Dart records and lets the repository handle fraction conversion and DB writes.

- Builds ticker string: `pairs.map((p) => '${p.from.toLowerCase()}${p.to.toLowerCase()}').join(',')`
- GETs the endpoint with `?tickers={tickers}`
- Parses response array into a record list
- **Normalizes** `from` / `to` to uppercase before returning — guards against case mismatch with `currencies.code` (uppercase per the seed)
- Throws on network or HTTP errors (`DioException` — caught by repository)

**Partial response handling:** The service returns only successfully parsed entries. The repository compares returned pairs against requested pairs; missing pairs are not touched in the DAO, preserving any existing cached row.

---

## Repository — `data/repositories/exchange_rate_repository.dart`

### Abstract Contract

```dart
abstract class ExchangeRateRepository {
  /// Fetches rates for every currency in use (excluding [defaultCurrency])
  /// and upserts results. Errors are caught and logged; on failure the
  /// cached snapshot from the DAO continues to back getRate(). Idempotent.
  Future<void> refreshAll(String defaultCurrency);

  /// Fetches a single pair on demand (used after creating a new
  /// non-default-currency account or transaction). Errors swallowed.
  Future<void> fetchRate(String from, String defaultCurrency);

  /// Synchronous lookup against the in-memory snapshot derived from
  /// dao.watchAll(). Returns `(numerator: 1, denominator: 1)` for
  /// same-currency pairs. Returns null when no rate is known.
  ({int numerator, int denominator})? getRate(String from, String to);

  /// Stream of the snapshot map. Drift's .watch() handles replay to new
  /// subscribers automatically — no custom replay logic required.
  Stream<Map<String, ({int numerator, int denominator})>> watchRates();
}
```

### Snapshot

`Map<String, ({int numerator, int denominator})> _snapshot` — keyed by `"FROM→TO"` string (e.g., `"HKD→USD"`). Dart records have value-equality, so map mutation is reactive-safe in Riverpod.

**Single mutation path:** The repository subscribes to `dao.watchAll()` in its constructor; each emission rebuilds `_snapshot` from the rows. No other code path mutates `_snapshot`. Writes go through `dao.upsertAll()` → `watchAll()` emits → snapshot rebuilds → listeners notified.

**Inverse rates:** When the API returns `HKD→USD: 0.1277`, the repository also writes `USD→HKD = (denominator, numerator)` (the swapped fraction) via the same `dao.upsertAll(...)` call. This lets `getRate()` work for either direction without knowing which way the API returned. **Round-trip drift tolerance:** Converting `100 HKD → USD → HKD` may drift by ±1 minor unit per leg because the conversion math rounds at the minor-unit boundary on each leg. Accepted for display purposes; assertions in tests use `closeTo(expected, 1)` not exact equality.

**Same-currency:** `getRate("USD", "USD")` always returns `(numerator: 1, denominator: 1)` — no DB lookup, no API call.

**Sanity bounds** (applied before upsert; rejected rates are not written, the existing cached row stays in place):

- `rate ≤ 0`
- `rate > 1_000_000` (sanity ceiling; guards against MITM/server bug)
- A prior cached rate exists for the pair **and** the new rate differs by >100× (likely server-side data error)

### Constructor

```dart
DriftExchangeRateRepository(this._db, this._service, Stream<String> defaultCurrency$) {
  _daoSub = _db.exchangeRateDao.watchAll().listen(_rebuildSnapshot);
  _currencySub = defaultCurrency$.listen((code) {
    unawaited(refreshAll(code));
  });
}
```

The constructor cannot throw — all error paths are inside the `.listen` handlers, which run async. The first `defaultCurrency$` emission triggers the initial `refreshAll`; bootstrap does not need to call any init function.

### refreshAll Flow

1. `pairs = await dao.distinctCurrenciesAcrossAllTables()` — set difference with `{defaultCurrency}`.
2. If `pairs.isEmpty` → return.
3. `await service.fetchRates([(c, defaultCurrency) for c in pairs])` — wrapped in `try/catch DioException`, logged at debug.
4. Apply sanity bounds to each row; convert valid doubles to fractions; compute inverse fractions.
5. `await dao.upsertAll(rows)` — `watchAll()` emits, `_snapshot` rebuilds, listeners notified.

On any step failing: existing DAO rows are unchanged; consumers see the previous snapshot.

### fetchRate Flow (on-demand)

Same sanity + upsert path as `refreshAll`, but for a single pair. Form save handlers fire this as `unawaited(...)` — caller does not await.

### Cross-Table Query — `distinctCurrenciesAcrossAllTables`

Lives on `ExchangeRateDao` rather than growing the existing `AccountRepository` / `TransactionRepository` / `PendingTransactionRepository` with a method only this feature needs:

```dart
Future<Set<String>> distinctCurrenciesAcrossAllTables() async {
  final rows = await customSelect(
    'SELECT DISTINCT currency FROM accounts '
    'UNION SELECT DISTINCT currency FROM transactions '
    'UNION SELECT DISTINCT currency FROM pending_transactions',
  ).get();
  return rows.map((r) => r.read<String>('currency')).toSet();
}
```

DAOs are allowed to issue arbitrary queries against the database they're attached to; cross-table reads belong in the DAO that owns the use case for them, not in the per-table DAOs.

### dispose

```dart
@override
void dispose() {
  _daoSub.cancel();
  _currencySub.cancel();
}
```

Riverpod's `keepAlive: true` provider invokes `dispose` only at app teardown; the subscriptions live for the app's lifetime.

---

## Conversion Logic — `core/utils/currency_converter.dart`

```dart
int convertMinorUnits({
  required int amountMinorUnits,
  required int rateNumerator,
  required int rateDenominator,
  required int fromDecimals,
  required int toDecimals,
}) {
  // target = amount * (num/denom) * 10^(toDecimals - fromDecimals)
  // Stay in integer arithmetic until the final result; use BigInt
  // for the intermediate to avoid int64 overflow on ETH-scale amounts.
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
```

`BigInt` is used for the multiplication because `amountMinorUnits × rateNumerator` can exceed int64 for ETH-scale amounts at 18 decimals × a 9-digit numerator. The final `.toInt()` is safe because the displayed value fits in int64 by construction (otherwise the user couldn't have stored the source amount).

Callers obtain `rateNumerator` / `rateDenominator` from `repo.getRate(from, to)` and skip the conversion when it returns null. Formatting uses `MoneyFormatter.format(amountMinorUnits: convertedMinorUnits, currency: toCurrency, locale: locale)` — `locale` comes from the existing `effectiveLocaleProvider` plumbing already used by tiles.

### Why not stay in double

Conversion runs at every tile build for every transaction with `fromCurrency != defaultCurrency`. Float multiplication is fine for one value, but accumulates ULP error when SummaryStrip sums 50 converted transactions and shows the total. Integer-fraction arithmetic is deterministic, audit-able, and matches the rest of the codebase's money-storage rules — see CLAUDE.md → Data-Model Invariants.

---

## Provider Wiring

All new providers follow the existing `@riverpod` annotation pattern with code generation (same as `repository_providers.dart:23-88`). Every provider signature uses bare `Ref ref` (matches the file's existing convention).

### Bootstrap — `lib/app/bootstrap.dart`

The repository constructs itself reactively via its provider: DAO subscription + default-currency subscription in the constructor body. Bootstrap does **not** call any init function. To ensure the repository instantiates before the first frame (so the DAO subscription begins draining), bootstrap reads its provider eagerly via the `ProviderContainer` built before `runApp`:

```dart
// In bootstrap.dart, after `final container = ProviderContainer(overrides: ...)`
// and before `runApp(UncontrolledProviderScope(container: container, child: const App()))`:
container.read(exchangeRateRepositoryProvider); // Force instantiation; no await.
```

This is a synchronous read — Riverpod constructs the repository, which begins its DAO subscription synchronously. The first network fetch happens off the first `defaultCurrencyProvider` emission, asynchronously, so no frame is blocked.

### Repository Provider — `lib/app/providers/repository_providers.dart`

```dart
@Riverpod(keepAlive: true, dependencies: [appDatabase, exchangeRateService, defaultCurrency])
ExchangeRateRepository exchangeRateRepository(Ref ref) {
  return DriftExchangeRateRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(exchangeRateServiceProvider),
    ref.watch(defaultCurrencyProvider.stream),
  );
}
```

`defaultCurrencyProvider.stream` is Riverpod's accessor for the underlying stream of a `StreamProvider`. Declaring `defaultCurrency` under `dependencies` satisfies the `scoped_providers_should_specify_dependencies` lint and matches the existing pattern in this file.

### Exchange Rate Service Provider — `lib/app/providers/repository_providers.dart`

```dart
@Riverpod(keepAlive: true, dependencies: [])
ExchangeRateService exchangeRateService(Ref ref) {
  return ExchangeRateService(Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )));
}
```

The `services_forbid_upstream_and_siblings` rule applies only to files matching `^lib/data/services/.*\.dart$`; importing `data/services/exchange_rate_service.dart` from `app/providers/` is allowed.

### Exchange Rates Stream Provider — `lib/app/providers/repository_providers.dart`

```dart
@Riverpod(keepAlive: true, dependencies: [exchangeRateRepository])
Stream<Map<String, ({int numerator, int denominator})>> exchangeRates(Ref ref) {
  return ref.watch(exchangeRateRepositoryProvider).watchRates();
}
```

`watchRates()` is a transform over `dao.watchAll()` — Drift handles replay automatically, so new subscribers receive the latest emitted snapshot. No custom `StreamController` or `_lastEmitted` field is required.

Placed in `app/providers/` (not a feature slice) because it's consumed by multiple features (home, accounts).

### Default Currency Provider — `lib/features/settings/settings_providers.dart`

```dart
@Riverpod(keepAlive: true, dependencies: [userPreferencesRepository])
Stream<String> defaultCurrency(Ref ref) {
  return ref.watch(userPreferencesRepositoryProvider).watchDefaultCurrency();
}
```

`watchDefaultCurrency()` returns `Stream<String>` emitting the ISO code (e.g., `"USD"`); the repo defaults to `'USD'` internally when the preference hasn't been set.

**File-level note:** `settings_providers.dart` currently has no `@riverpod` providers — adding the first one requires `part 'settings_providers.g.dart';` at the top of the file plus a `dart run build_runner build` regen before tests will compile.

### On-Demand Fetch — `AccountFormActions` and `TransactionFormController`

After saving an account or transaction in a non-default currency:

```dart
final repo = ref.read(exchangeRateRepositoryProvider);
final defaultCurrency = await ref.read(defaultCurrencyProvider.future);
if (newCurrency != defaultCurrency) {
  unawaited(repo.fetchRate(newCurrency, defaultCurrency));
}
```

Locations to modify:

- `lib/features/accounts/accounts_providers.dart` — wrap the existing `AccountFormActions.save()` pass-through so the post-save fetch fires after the underlying `_accountRepository.save(draft)` resolves with the new account ID.
- `lib/features/transactions/transaction_form_controller.dart` — inside `TransactionFormController`'s save command, after the successful insert.

The form action is the right hook because it has access to both the just-saved currency and the Riverpod `ref`. Restore/import flows that bulk-add transactions in new currencies are out of scope for on-demand fetch; they fall through to the next `refreshAll` on the following app launch.

---

## Rate Lifecycle

- **Never expire.** Cached rates from any past fetch remain usable indefinitely. **This is a deliberate product decision** — see Out of Scope. Trade-off: a user offline for weeks sees converted totals computed from old rates with no visible staleness signal. Accepted; revisit only if user feedback raises concerns.
- **Pairs the API stops returning** keep their last-known value in the DAO. There is no "evict if not seen this session" sweep — an absent pair in a response is indistinguishable from "we didn't request it."
- **Default-currency change** triggers `refreshAll(newDefault)` from the subscription handler. Rows keyed to a prior default are not deleted; they remain in the DAO for the case where the user switches back, and Drift `.watch()` ensures the snapshot always reflects whatever rows exist.

---

## UI Changes

### SummaryStrip — `lib/features/home/widgets/summary_strip.dart`

**Before:** Renders up to 2 currency groups with per-currency expense/income/month-net. Shows "Multiple currencies" note when >2 groups.

**After:** Single unified total in the default currency. Each amount is converted through `CurrencyConverter.convertMinorUnits` using the integer fraction from `repo.getRate(from, default)`.

- `todayTotalsByCurrency` map iterated, each currency's amounts converted to default, then summed.
- `monthNetByCurrency` same treatment.
- Renders one group: `Default currency: −$X / +$Y` (today), `−$Z` (month).
- **Per-row fallback:** if a rate is missing for *one* currency in the iteration, only that currency's contribution falls back to per-currency display alongside the unified total for the rest; the strip is not all-or-nothing.
- **Cold-start transition:** wrap the strip's contents in `AnimatedSize(duration: Duration(milliseconds: 150))` so the height change between fallback and unified states is a smooth resize rather than a hard pop.

### TransactionTile — `lib/features/home/widgets/transaction_tile.dart`

**After:** Original amount primary (unchanged). Converted amount as secondary line below:

```
−€5.40
≈ −$6.31
```

- Converted line **hidden** when `repo.getRate(from, default)` returns null.
- Converted line **hidden** when `fromCurrency == defaultCurrency` (same-currency suppression — avoids `≈ $5.00` directly under `$5.00`).
- Converted line uses `Theme.of(context).textTheme.bodySmall` with `color: outline` (muted color is one of three non-color differentiators; see [Accessibility](#accessibility)).
- The tile's amount column reserves a fixed inner height (`SizedBox(height: bodySmall.fontSize! * 1.4)`) so that the tile height does **not** change when a rate later becomes available. This eliminates SliverList reflow on rate arrival and across rate-loaded vs. rate-missing tiles.

### AccountTile — `lib/features/accounts/widgets/account_tile.dart`

**After:** Per-currency balances kept as-is. Converted total added below with a `Divider` separator:

```
EUR: €1,250.00
USD: $340.00
─────────────
≈ $1,802.50 total
```

- Converted total sums all currency groups after conversion.
- **Hidden entirely** (no separator, no total line) when:
  - The account has a single currency (single-currency total would just duplicate the row above), **or**
  - No rate is available for any of the account's currencies.
- **Visible-currency cap:** Accounts with >4 currencies show the first 4 groups + a `Show {n} more` tap affordance; the converted total always sums **all** currencies, not just the visible ones.
- Separator is a `Divider(thickness: 1, indent: 16, endIndent: 16, color: outline)` — not text characters. Wrapped in `ExcludeSemantics` so screen readers don't announce it.
- Uses muted color + `≈` prefix with Semantics label.

### Loading & Empty States

- **First launch with rates already in DB:** the DAO emits the cached snapshot before the first frame in practice; converted lines render immediately.
- **First launch with empty DB + slow network:** all converted lines are hidden until the first `dao.upsertAll()` completes. No loading spinner or skeleton — the converted line is supplementary, not primary content.
- **Within-session rate arrival** (e.g., on-demand fetch after creating a new-currency account): the affected tile's `AnimatedSize` cross-fades the converted line in over 150 ms.

---

## Localization (l10n)

New ARB keys (add to `l10n/app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`, `app_zh_TW.arb`):

| Key                       | en              | zh / zh_CN       | zh_TW              |
|---------------------------|-----------------|------------------|--------------------|
| `approximatelyPrefix`     | "approximately" | "约"              | "約"                |
| `convertedTotalLabel`     | "total"         | "总计"             | "總計"               |
| `accountTileShowMore`     | "Show {n} more" | "查看其他 {n} 项"   | "查看其他 {n} 項"      |

The `≈` glyph itself is rendered as a Unicode character in the visible UI; the spoken/screen-reader label comes from `approximatelyPrefix` via Semantics. The base `app_zh.arb` keeps its `appTitle` entry per the CLAUDE.md fallback requirement and inherits the rest from `zh_CN` at runtime.

---

## Accessibility

- **Color is never the sole differentiator** between converted and original amounts. The converted line uses (a) muted color, (b) smaller font (`bodySmall` vs. `bodyMedium`), (c) a leading `≈` glyph, and (d) a `Semantics(label: l10n.approximatelyPrefix)` annotation read by screen readers.
- The `Divider` separator in AccountTile is decorative — wrap in `ExcludeSemantics`.
- All scrollable regions in this feature survive 2× text scale (CLAUDE.md → Layout Primitives). Fixed-height widgets inside tiles size their reserved space in `em` (multiplied by font size) rather than logical pixels so they reflow with text scale.

---

## Error Handling

| Scenario                                                           | Behavior                                                                       |
|--------------------------------------------------------------------|--------------------------------------------------------------------------------|
| API unreachable on startup                                         | Silent catch (`DioException`); use cached rows from DAO                        |
| HTTP 500 / 429 / non-200                                           | Silent catch; HTTP 401/403 additionally logged at **warn** (future auth signal)|
| Partial API response                                               | Upsert available pairs; missing pairs retain any existing cached row           |
| Malformed response entry                                           | Skip, log to debug console                                                     |
| First launch + no network + empty DB                               | Converted lines hidden across all surfaces; app functions normally             |
| Rate ≤ 0                                                           | Skip, don't cache, keep existing cached row                                    |
| Rate > 1,000,000                                                   | Skip (sanity ceiling); keep existing cached row; log at debug                  |
| Rate differs by >100× from cached rate for the same pair           | Skip (likely server-side data error); keep cached row; log at debug            |
| Response currency code in unexpected case                          | Normalized to uppercase at the service layer before the repository sees it     |
| Currency not in `currencies` table after normalization             | FK constraint rejects; repository catches and logs at debug                    |
| `init` would throw synchronously                                   | Cannot happen — `init` no longer exists; constructor performs no failing work  |

---

## Testing

### Unit Tests

| Test                                 | File                      | Coverage                                                                                                                                                                                |
|--------------------------------------|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `exchange_rate_service_test.dart`    | `test/unit/services/`     | HTTP call construction, ticker formatting, response parsing, **uppercase normalization**, error handling. Mock `Dio`.                                                                   |
| `exchange_rate_repository_test.dart` | `test/unit/repositories/` | DAO subscription wires snapshot; upsert + inverse fraction; sanity-bound rejection (0/negative/>1M/>100×); partial response handling; default-currency-change re-fetch; on-demand fetch. In-memory Drift DB + mock service + manual `defaultCurrency$` `StreamController`. |
| `currency_converter_test.dart`       | `test/unit/utils/`        | Integer-fraction conversion with USD→USD, JPY→USD, EUR→CNY, **ETH→USD at 18 decimals** (BigInt path), rounding, round-trip drift bound (±1 minor unit).                                  |

### Widget Tests

| Test                                    | File                             | Coverage                                                                                                                                  |
|-----------------------------------------|----------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| `summary_strip_conversion_test.dart`    | `test/widget/features/home/`     | Unified total; per-row fallback when one rate missing; AnimatedSize transition.                                                            |
| `transaction_tile_conversion_test.dart` | `test/widget/features/home/`     | Secondary converted line appears; hidden when same-currency; hidden when rate missing; fixed inner height preserved across both states.    |
| `account_tile_conversion_test.dart`     | `test/widget/features/accounts/` | Converted total below per-currency balances; hidden for single-currency accounts; "Show N more" affordance past the 4-currency cap.        |

### Integration Test

| Test                                 | File                | Coverage                                                                                                                            |
|--------------------------------------|---------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| `currency_conversion_flow_test.dart` | `test/integration/` | Bootstrap → snapshot loads from DB → API call → UI shows converted amounts → switch default currency in Settings → re-fetch → UI updates. |

### Migration Test

Extend `test/unit/repositories/migration_test.dart` with v5 schema helpers:

- Generate v5 schema helper via `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/`
- Create `test/unit/repositories/_harness/generated/schema_v5.dart` from the dump
- Validate v4→v5 upgrade creates `exchange_rates` table and unique index
- Run v4→v5 `onUpgrade` against both an empty DB **and** a seeded DB (matches existing migration-test convention in `CLAUDE.md` → Testing)
- After migration, verify the FK to `currencies(code)` is enforced (inserting an exchange_rate with a non-existent code must fail)
- Verify the `CHECK(rate_denominator > 0)` constraint is enforced (inserting a row with `rate_denominator = 0` must fail)
- Validate `PRAGMA foreign_keys` remains enabled after upgrade

### Mocking Strategy

- Service tests: mock `Dio`
- Repository tests: in-memory Drift DB + mock service + manual `StreamController<String>` driving `defaultCurrency$`
- Widget tests: override `exchangeRateRepositoryProvider` with a fake returning preset fraction maps
- Integration test: mock service with fixture data, real in-memory Drift DB

---

## PRD Updates Required

The following sections of `PRD.md` should be updated to reflect this design:

1. **Folder structure** — add `exchange_rate_service.dart` and `exchange_rate_repository.dart`; **do not** add `exchange_rate.dart` (no Freezed model — the design uses the DAO row + service records directly).
2. **`exchange_rates` table schema** — keep the integer-fraction design from the original PRD; **remove** the `provider` column. Add the unique index on `(base_currency, quote_currency)` and the `CHECK(rate_denominator > 0)` constraint.
3. **Phase 2 roadmap** — mark this feature (SummaryStrip / TransactionTile / AccountTile only) as "in progress." Add a sub-bullet: "Analysis surfaces (charts, search) in default currency — follow-up spec, deferred."
4. **MVP Currency Policy** — note that Phase 2 conversion is live for Home and Accounts.
5. **Dependencies table** — mark `dio` as in-use.
6. **Cloudflare Worker spec** (`docs/superpowers/specs/2026-05-11-ledgerly-api-cloudflare-worker-design.md`) — add the `/api/conversion` route with ticker parsing/validation, upstream rate source, response shape, and worker-side caching.

---

## Migration Strategy

Drift schema bump from `schemaVersion = 4` to `schemaVersion = 5`. `onUpgrade` creates the `exchange_rates` table for installs upgrading from v4:

```sql
CREATE TABLE exchange_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  base_currency TEXT NOT NULL REFERENCES currencies(code),
  quote_currency TEXT NOT NULL REFERENCES currencies(code),
  rate_numerator INTEGER NOT NULL,
  rate_denominator INTEGER NOT NULL CHECK(rate_denominator > 0),
  fetched_at DATETIME NOT NULL
);
CREATE UNIQUE INDEX idx_exchange_rates_pair ON exchange_rates(base_currency, quote_currency);
```

Fresh installations at v5 get the table from the main schema creation. No data migration needed — new table, no existing data affected. The migration is tested on both empty and seeded v4 databases (see Migration Test).

---

## Follow-up Tasks (tracked separately, not in this spec)

- **Phase 2.1 — Worker auth + rate limiting.** App-identifier header (HMAC-signed token derived from a build-time secret), worker-side rate limits keyed by header + IP, `401`/`429` responses surfaced as warn-level app logs.
- **Phase 2.1 — TLS certificate pinning.** Pin Cloudflare's intermediate CA via `dio`'s `HttpClientAdapter`.
- **Analysis surfaces in default currency.** Separate spec extending `analysis_state.dart` / `analysis_controller.dart` to carry per-transaction currency through to the search result model and chart series builders.
