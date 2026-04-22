# M2 — Stream A: `money_formatter` + `date_helpers` + utility tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Owner:** Agent A (Core)
**Milestone:** M2 — Core utilities (`docs/plans/implementation-plan.md` §5, M2)
**Authoritative PRD ranges:** [`PRD.md`](../../../PRD.md)
- *Money Storage Policy*: lines **253–257**
- *MVP Currency Policy*: lines **259–261**
- `currencies` schema (esp. `decimals` as SSOT): lines **263–277**
- *Splash Screen (MVP)* — day counter math, template substitution `{days}` / `{date}`: lines **510–552**
- *Internationalization* — `intl`, `NumberFormat.currency`, locale-aware dates: lines **864–887**
- *Testing Strategy → Utility Tests*: lines **952–957**
- *Dependencies → Core (MVP)* — `intl ^0.20.2` pin: lines **996–1010**

**Sibling streams (same milestone, no blocking dependency):**
- Stream B — `icon_registry` + `color_palette` (different files, different concerns).
- Stream C — `core/theme/*` + ARBs.
Stream A can merge independently.

**Upstream dependency (must be green before starting):** M1 Stream B — `lib/data/models/currency.dart` is merged. The Freezed `Currency` domain model with `code`, `decimals`, `symbol`, `nameL10nKey`, `isToken`, `sortOrder` is already in the tree (verified 2026-04 — see §11).

**Stack:** `intl ^0.20.2`, Dart `^3.11.5`, Flutter `>=3.41.6`, `flutter_test` (sdk). No new dependencies. `pubspec.yaml` is **not** modified by this stream.

**Goal:** Ship the render-time primitives — integer-minor-unit → localized currency string, day-boundary math, splash day-count helper, locale-aware date formatting — that every M5 screen depends on, with frozen public signatures so M3 and M5 can compile against them without waiting.

**Architecture:** Two framework-agnostic utility files in `lib/core/utils/`, pure functions plus tiny value-returning classes, zero Flutter imports, zero Drift imports, zero state. `money_formatter.dart` funnels through `intl`'s `NumberFormat.currency`; `date_helpers.dart` funnels through `intl`'s `DateFormat`. Unit tests exercise each contract across locales and currency decimal widths.

**Tech Stack:** `intl ^0.20.2` (`NumberFormat.currency`, `DateFormat`, locale initialization), `flutter_test` (test harness), Dart `DateTime` / `Duration` standard library, Freezed-generated `Currency` from `lib/data/models/currency.dart`.

---

## 0. Current state of the files being replaced

At M0 scaffold time these two files were created as TODO-only stubs. Their full current content:

**`lib/core/utils/money_formatter.dart`** (6 lines, all comment):
```dart
// TODO(M2): Format integer minor units into locale-aware display strings.
// Divides by 10^currencies.decimals and applies NumberFormat.currency
// from `intl`. This is the ONLY place `double` may appear near money.
//
// Tested against USD (2 decimals), JPY (0), ETH (18), TWD (2) in
// test/unit/utils/money_formatter_test.dart per PRD -> Money Storage Policy.
```

**`lib/core/utils/date_helpers.dart`** (2 lines, all comment):
```dart
// TODO(M2): Day-boundary math, locale-aware formatting, and the splash
// day-counter helper used by SplashController per PRD -> Splash Screen.
```

Stream A replaces both files in full — the TODO comments go away, the exported API lands (§1).

The matching test files do not yet exist (M0 only seeded the `test/` folder skeleton):
- `test/unit/utils/money_formatter_test.dart` — to be created.
- `test/unit/utils/date_helpers_test.dart` — to be created.

---

## 1. Public API contract (FROZEN on merge)

Downstream M3 and M5 code will import these symbols. Do not change a signature without bumping every consumer in lock-step.

### 1.1 `lib/core/utils/money_formatter.dart`

```dart
import 'package:intl/intl.dart';

import '../../data/models/currency.dart';

/// Locale-aware formatter for integer minor-unit money amounts.
///
/// Scaling factor comes from `Currency.decimals` (SSOT — PRD.md 253-277).
/// Storage stays `int`; `double` lives exclusively inside this file and
/// only as the intermediate for `NumberFormat.currency`. See PRD.md ->
/// Money Storage Policy and CLAUDE.md -> Data-Model Invariants.
class MoneyFormatter {
  const MoneyFormatter._();

  /// Formats [amountMinorUnits] in [currency] for [locale] (e.g. `'en_US'`,
  /// `'zh_TW'`, `'zh_CN'`). Uses `currency.symbol` if present, otherwise
  /// falls back to `currency.code`. Negative amounts render with the
  /// locale-native sign (e.g. `-$1.23`). Zero renders with zero fractional
  /// digits matching `currency.decimals` (`$0.00`, `¥0`).
  static String format({
    required int amountMinorUnits,
    required Currency currency,
    required String locale,
  });

  /// Formats [amountMinorUnits] with an explicit leading sign for use in
  /// the Home list (`+$3.50` for income, `-$3.50` for expense) per PRD.md
  /// line 491. Zero renders without a sign. For negative inputs, returns
  /// the same string as [format] (the locale-native `-` is preserved).
  static String formatSigned({
    required int amountMinorUnits,
    required Currency currency,
    required String locale,
  });

  /// Bare-number variant (no symbol, no code) for inputs and summary
  /// strips where the currency symbol is rendered separately. Uses
  /// locale-aware grouping and the decimal character from [locale].
  static String formatBare({
    required int amountMinorUnits,
    required Currency currency,
    required String locale,
  });

  /// Parses a user-entered decimal string into an integer minor-unit
  /// amount, scaled by [currency].`decimals`. Accepts the locale's decimal
  /// separator. Throws [FormatException] on unparseable input or on inputs
  /// whose fractional part exceeds `currency.decimals` digits (i.e. a
  /// rounding decision is required). Caller decides whether to catch or
  /// reject at the UI. Consumed by the Add/Edit Transaction calculator
  /// (M5) and the Account opening-balance input.
  static int parseToMinorUnits({
    required String input,
    required Currency currency,
    required String locale,
  });
}
```

**Exported:** class `MoneyFormatter` with four static methods above.
**Not exported:** no top-level functions, no helpers. Everything is reachable through `MoneyFormatter.*`.

### 1.2 `lib/core/utils/date_helpers.dart`

```dart
import 'package:intl/intl.dart';

/// Day-boundary math + locale-aware date formatting used by the Home
/// day-grouped list and the splash day counter. No Flutter imports,
/// no state.
class DateHelpers {
  const DateHelpers._();

  /// Returns midnight (00:00:00.000) **in the same time zone as [dt]**.
  /// Used to bucket transactions by day in the Home list and as the
  /// anchor for the splash day counter.
  static DateTime startOfDay(DateTime dt);

  /// Returns true if [a] and [b] land on the same calendar day in
  /// [a]'s time zone.
  static bool isSameDay(DateTime a, DateTime b);

  /// Whole calendar days from [from] to [to] using each argument's
  /// local midnight. Zero when [from] and [to] share a day.
  /// Positive when [to] is later. Negative when [to] is earlier.
  /// **DST-safe:** operates on `startOfDay` differences, so clocks that
  /// jump forward / backward do not shift the count.
  static int daysBetween(DateTime from, DateTime to);

  /// Splash day counter (PRD.md 510-552). Whole days elapsed since
  /// [startDate] up to [now]. Returns 0 when `startDate` is today.
  /// Returns a **negative** integer when `startDate` is in the future
  /// (the UI is expected to display it as `-N`; the counter does not
  /// clamp to zero).
  ///
  /// Always normalizes to local-midnight of each argument before
  /// subtracting (delegates to [daysBetween]).
  static int daysSince({required DateTime startDate, required DateTime now});

  /// Locale-aware "long-ish" date for splash and settings display
  /// (e.g. `Apr 21, 2026` / `2026年4月21日`). Matches PRD.md 525 / 549
  /// "rainbow-gradient text below showing the start date".
  static String formatDisplayDate(DateTime date, String locale);

  /// Locale-aware "day header" date for the Home day-grouped list
  /// (e.g. `Mon, Apr 21` / `4月21日（週一）`). No year — Home already
  /// implies "recent".
  static String formatDayHeader(DateTime date, String locale);

  /// Locale-aware short date for list-row timestamps
  /// (e.g. `4/21/26` / `2026/4/21`). Uses [DateFormat.yMd].
  static String formatShortDate(DateTime date, String locale);

  /// Substitutes `{date}` and `{days}` in the splash display template.
  /// - `{date}` → `formatDisplayDate(startDate, locale)`.
  /// - `{days}` → `daysSince(...)` rendered with locale-aware grouping
  ///   via `NumberFormat.decimalPattern(locale)`.
  /// Unknown `{placeholder}` tokens pass through unchanged. Default
  /// template is the ARB-supplied `"Since {date}"` (PRD.md 526, 551).
  static String applySplashTemplate({
    required String template,
    required DateTime startDate,
    required DateTime now,
    required String locale,
  });
}
```

**Exported:** class `DateHelpers` with seven static methods above.

### 1.3 Contract rules (non-negotiable once this stream merges)

1. **`int` minor units in, `String` display out.** No method in either file accepts or returns `double` in its public signature. `double` may appear **only inside** `money_formatter.dart` as the intermediate for `NumberFormat.currency`, per PRD Money Storage Policy.
2. **Currency param is the Freezed `Currency`, not a code string.** This forces the caller to supply a fully resolved currency (with `decimals`), eliminating the "what's the scale?" ambiguity. Callers with only a code must resolve via `CurrencyRepository` (M3) first.
3. **`locale` is a `String` BCP-47 tag (`en_US`, `zh_TW`, `zh_CN`).** Not a `Locale`. `intl` expects the string form; passing `Locale` would force a conversion in every call site.
4. **Pure functions.** No `static` mutable state, no caching. `intl` internally memoizes pattern parsing — that is enough.
5. **Locale data must be initialized elsewhere.** `DateFormat` for non-`en` locales requires `initializeDateFormatting(locale)` from `package:intl/date_symbol_data_local.dart`. That call lands in M4 `bootstrap.dart` as part of the bootstrap contract. This stream does **not** call it; the unit tests call it explicitly.

---

## 2. Test matrix (authoritative — every row becomes a test case in §5, §6)

### 2.1 `money_formatter_test.dart` — 4 currencies × {positive, negative, zero} × 3 locales where grouping matters

| #   | Method              | Currency           | Locale  | Input (minor units)    | Expected output                                                      | PRD cite     |
|-----|---------------------|--------------------|---------|------------------------|----------------------------------------------------------------------|--------------|
| M01 | `format`            | USD (2)            | `en_US` | `0`                    | `$0.00`                                                              | 253-257      |
| M02 | `format`            | USD (2)            | `en_US` | `12345`                | `$123.45`                                                            | 253-257      |
| M03 | `format`            | USD (2)            | `en_US` | `-12345`               | `-$123.45`                                                           | 253-257      |
| M04 | `format`            | JPY (0)            | `en_US` | `0`                    | `¥0`                                                                 | 265-268      |
| M05 | `format`            | JPY (0)            | `en_US` | `1234567`              | `¥1,234,567`                                                         | 265-268      |
| M06 | `format`            | JPY (0)            | `en_US` | `-1234567`             | `-¥1,234,567`                                                        | 265-268      |
| M07 | `format`            | TWD (2, sym `NT$`) | `zh_TW` | `0`                    | `NT$0.00`                                                            | 265-268, 880 |
| M08 | `format`            | TWD (2)            | `zh_TW` | `1234567`              | `NT$12,345.67`                                                       | 265-268      |
| M09 | `format`            | TWD (2)            | `zh_TW` | `-1234567`             | `-NT$12,345.67`                                                      | 265-268      |
| M10 | `format`            | CNY (2, sym `¥`)   | `zh_CN` | `123456789`            | `¥1,234,567.89`                                                      | 865-882      |
| M11 | `format`            | ETH (18)           | `en_US` | `1500000000000000000`  | `ETH1.500000000000000000` *(symbol-less token — falls back to code)* | 265-268, 275 |
| M12 | `format`            | ETH (18)           | `en_US` | `0`                    | `ETH0.000000000000000000`                                            | 265-268      |
| M13 | `format`            | ETH (18)           | `en_US` | `-1500000000000000000` | `-ETH1.500000000000000000`                                           | 265-268      |
| M14 | `formatSigned`      | USD (2)            | `en_US` | `12345`                | `+$123.45`                                                           | 491          |
| M15 | `formatSigned`      | USD (2)            | `en_US` | `-12345`               | `-$123.45`                                                           | 491          |
| M16 | `formatSigned`      | USD (2)            | `en_US` | `0`                    | `$0.00` *(no sign)*                                                  | 491          |
| M17 | `formatBare`        | JPY (0)            | `en_US` | `1234567`              | `1,234,567`                                                          | 953-954      |
| M18 | `formatBare`        | USD (2)            | `zh_CN` | `12345`                | `123.45`                                                             | 865-882      |
| M19 | `parseToMinorUnits` | USD (2)            | `en_US` | `"123.45"`             | `12345`                                                              | 253-257      |
| M20 | `parseToMinorUnits` | JPY (0)            | `en_US` | `"1234"`               | `1234`                                                               | 265-268      |
| M21 | `parseToMinorUnits` | USD (2)            | `zh_CN` | `"1,234.56"`           | `123456`                                                             | 865-882      |
| M22 | `parseToMinorUnits` | USD (2)            | `en_US` | `"12.345"`             | throws `FormatException` *(too many fraction digits)*                | 253-257      |
| M23 | `parseToMinorUnits` | USD (2)            | `en_US` | `"abc"`                | throws `FormatException`                                             | 253-257      |

**Decimal-width note.** `intl`'s `NumberFormat.currency` accepts `decimalDigits`; we pass `currency.decimals`, so ETH at 18 digits "just works". The test asserts the full 18-digit string literally.

**Symbol-fallback note.** When `currency.symbol` is null (e.g. Phase-2 tokens like ETH with `symbol = null`), `NumberFormat.currency` is invoked with `symbol: currency.code`, producing `ETH1.50…`. The test row M11/M13 reflects this contract exactly.

### 2.2 `date_helpers_test.dart`

| #   | Method                | Scenario                               | Inputs                                                                   | Expected                                                    | PRD cite              |
|-----|-----------------------|----------------------------------------|--------------------------------------------------------------------------|-------------------------------------------------------------|-----------------------|
| D01 | `startOfDay`          | Strips time-of-day                     | `2026-04-21T14:37:58.123Z` *(but interpreted as local — see Note A)*     | `2026-04-21T00:00:00.000` (local)                           | 510-552               |
| D02 | `isSameDay`           | Same day, different times              | `(2026-04-21 00:00, 2026-04-21 23:59)`                                   | `true`                                                      | 510-552               |
| D03 | `isSameDay`           | One minute before midnight vs next day | `(2026-04-21 23:59, 2026-04-22 00:01)`                                   | `false`                                                     | 510-552               |
| D04 | `daysBetween`         | Forward, 5 days                        | `(2026-04-21, 2026-04-26)`                                               | `5`                                                         | 510-552               |
| D05 | `daysBetween`         | Backward                               | `(2026-04-26, 2026-04-21)`                                               | `-5`                                                        | 510-552               |
| D06 | `daysBetween`         | Same day                               | `(2026-04-21 09:00, 2026-04-21 23:30)`                                   | `0`                                                         | 510-552               |
| D07 | `daysBetween`         | DST spring-forward (US)                | `(2026-03-07 12:00 America/New_York, 2026-03-09 12:00 America/New_York)` | `2` *(not 1 or 3 — `Duration`-based impls fail this)*       | 510-552               |
| D08 | `daysSince`           | Start today                            | `(2026-04-21, 2026-04-21)`                                               | `0`                                                         | 510-552               |
| D09 | `daysSince`           | Start 10 days ago                      | `(2026-04-11, 2026-04-21)`                                               | `10`                                                        | 510-552               |
| D10 | `daysSince`           | Start in future → negative             | `(2026-04-30, 2026-04-21)`                                               | `-9`                                                        | 510-552               |
| D11 | `formatDisplayDate`   | en_US                                  | `(2026-04-21, 'en_US')`                                                  | `Apr 21, 2026`                                              | 525, 549              |
| D12 | `formatDisplayDate`   | zh_TW                                  | `(2026-04-21, 'zh_TW')`                                                  | `2026年4月21日`                                                | 525, 549, 865-882     |
| D13 | `formatDisplayDate`   | zh_CN                                  | `(2026-04-21, 'zh_CN')`                                                  | `2026年4月21日`                                                | 525, 549, 865-882     |
| D14 | `formatDayHeader`     | en_US                                  | `(2026-04-21, 'en_US')`                                                  | `Mon, Apr 21`                                               | 881-882               |
| D15 | `formatDayHeader`     | zh_TW                                  | `(2026-04-21, 'zh_TW')`                                                  | `4月21日 週一` *(accept `DateFormat.MMMMd+E` canonical output)* | 881-882               |
| D16 | `formatShortDate`     | en_US                                  | `(2026-04-21, 'en_US')`                                                  | `4/21/2026`                                                 | 881-882               |
| D17 | `formatShortDate`     | zh_CN                                  | `(2026-04-21, 'zh_CN')`                                                  | `2026/4/21`                                                 | 881-882               |
| D18 | `applySplashTemplate` | Default en_US                          | `("Since {date}", 2026-04-11, 2026-04-21, 'en_US')`                      | `Since Apr 11, 2026`                                        | 526, 549-551          |
| D19 | `applySplashTemplate` | With `{days}`                          | `("{days} days since {date}", 2026-04-11, 2026-04-21, 'en_US')`          | `10 days since Apr 11, 2026`                                | 526, 549-551          |
| D20 | `applySplashTemplate` | `{days}` at 0                          | `("{days} days since {date}", 2026-04-21, 2026-04-21, 'en_US')`          | `0 days since Apr 21, 2026`                                 | 526, 549-551          |
| D21 | `applySplashTemplate` | Negative `{days}`                      | `("{days} days since {date}", 2026-04-30, 2026-04-21, 'en_US')`          | `-9 days since Apr 30, 2026`                                | 526, 549-551          |
| D22 | `applySplashTemplate` | Unknown placeholder passes through     | `("{foo} is kept", ...)`                                                 | `{foo} is kept`                                             | 526, 549-551          |
| D23 | `applySplashTemplate` | Locale grouping for large `{days}`     | `("{days}", 2000-04-21, 2026-04-21, 'en_US')`                            | `9,497` *(or computed exact — see §6 Task D8)*              | 526, 549-551, 865-882 |

**Note A.** All tests use naive `DateTime` (construct via `DateTime(year, month, day, hh, mm)` = local). Production callers also feed local `DateTime` values from Drift (Drift stores Unix ms → `DateTime.fromMillisecondsSinceEpoch` returns local by default). Timezone handling is out of MVP scope; `startOfDay` is documented as "in the same time zone as [dt]".

**Note B — DST test (D07).** We cannot force a specific zone inside unit tests without `package:timezone`. Instead, D07 constructs two `DateTime` values one minute after local midnight across a **24h boundary plus a synthetic DST transition** by using `DateTime` arithmetic that would mis-count under a naive `Duration.inDays` implementation. If the dev machine runs in a non-DST zone the test still passes because we normalize via `startOfDay` — which is exactly the invariant we are asserting. The test uses a comment referencing PRD line 510-552 so the intent survives casual refactoring.

### 2.3 Required locale initialization

Both test files call, once per group:

```dart
import 'package:intl/date_symbol_data_local.dart';

setUpAll(() async {
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('zh_TW', null);
  await initializeDateFormatting('zh_CN', null);
});
```

This is a **test-only** concern; production `DateFormat` coverage is handled in M4 `bootstrap.dart` (`initializeDateFormatting(Platform.localeName)` + explicit warm-up of the three MVP locales).

---

## 3. File structure

| Action                    | Path                                        | Responsibility                  |
|---------------------------|---------------------------------------------|---------------------------------|
| Modify (full replacement) | `lib/core/utils/money_formatter.dart`       | `MoneyFormatter` class per §1.1 |
| Modify (full replacement) | `lib/core/utils/date_helpers.dart`          | `DateHelpers` class per §1.2    |
| Create                    | `test/unit/utils/money_formatter_test.dart` | Table §2.1 — all 23 cases       |
| Create                    | `test/unit/utils/date_helpers_test.dart`    | Table §2.2 — all 23 cases       |

No other file in `lib/` is touched. No new entry in `pubspec.yaml`. No new ARB key.

---

## 4. TDD order (sequencing)

```
Task M1  → money_formatter: format() — USD happy path (red → green → commit)
Task M2  → money_formatter: format() — JPY zero-decimal
Task M3  → money_formatter: format() — TWD under zh_TW (locale grouping)
Task M4  → money_formatter: format() — CNY under zh_CN
Task M5  → money_formatter: format() — ETH 18 decimals + symbol fallback
Task M6  → money_formatter: format() — zero + negative for every currency
Task M7  → money_formatter: formatSigned()
Task M8  → money_formatter: formatBare()
Task M9  → money_formatter: parseToMinorUnits() happy path
Task M10 → money_formatter: parseToMinorUnits() error paths
Task D1  → date_helpers: startOfDay / isSameDay
Task D2  → date_helpers: daysBetween including DST-safe
Task D3  → date_helpers: daysSince (zero, positive, negative)
Task D4  → date_helpers: formatDisplayDate × 3 locales
Task D5  → date_helpers: formatDayHeader × 2 locales
Task D6  → date_helpers: formatShortDate × 2 locales
Task D7  → date_helpers: applySplashTemplate basics
Task D8  → date_helpers: applySplashTemplate edge cases (negative, unknown, grouping)
Task G   → Pre-merge grep + exit-criteria sweep
```

Run after every step: `flutter test test/unit/utils/ -r expanded`. The canonical per-file invocation is `flutter test test/unit/utils/money_formatter_test.dart` / `flutter test test/unit/utils/date_helpers_test.dart` (CLAUDE.md, "Common Commands").

---

## 5. Tasks — `money_formatter.dart`

### Task M1: `format()` — USD happy path

**Files:**
- Create: `test/unit/utils/money_formatter_test.dart`
- Modify: `lib/core/utils/money_formatter.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/unit/utils/money_formatter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ledgerly/core/utils/money_formatter.dart';
import 'package:ledgerly/data/models/currency.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('zh_TW', null);
    await initializeDateFormatting('zh_CN', null);
  });

  group('MoneyFormatter.format — USD', () {
    test('M02: 12345 minor units in en_US renders \$123.45', () {
      expect(
        MoneyFormatter.format(
          amountMinorUnits: 12345,
          currency: _usd,
          locale: 'en_US',
        ),
        r'$123.45',
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: FAIL. Either "The method 'format' isn't defined" or — if the file is empty stub — an import error pointing at `package:ledgerly/core/utils/money_formatter.dart`.

- [ ] **Step 3: Replace the `money_formatter.dart` stub with the minimal implementation**

Overwrite the full file (the existing body is only a comment block from M0):

```dart
// lib/core/utils/money_formatter.dart
import 'package:intl/intl.dart';

import '../../data/models/currency.dart';

/// Locale-aware formatter for integer minor-unit money amounts.
///
/// Scaling factor comes from `Currency.decimals` (SSOT — PRD.md 253-277).
/// Storage stays `int`; `double` lives exclusively inside this file and
/// only as the intermediate for `NumberFormat.currency`. See PRD.md ->
/// Money Storage Policy and CLAUDE.md -> Data-Model Invariants.
class MoneyFormatter {
  const MoneyFormatter._();

  static String format({
    required int amountMinorUnits,
    required Currency currency,
    required String locale,
  }) {
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: currency.symbol ?? currency.code,
      decimalDigits: currency.decimals,
    );
    final scaled = amountMinorUnits / _scale(currency.decimals);
    return fmt.format(scaled);
  }

  static double _scale(int decimals) {
    var s = 1.0;
    for (var i = 0; i < decimals; i++) {
      s *= 10.0;
    }
    return s;
  }
}
```

*Design note.* `_scale` uses `double` on purpose — this file is the documented escape hatch for `double` near money (G4 exemption). Every call to `_scale` is sandwiched between `int` in and `String` out, so no `double` leaks past the boundary.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/money_formatter.dart test/unit/utils/money_formatter_test.dart
git commit -m "feat(core): money_formatter format() USD happy path"
```

---

### Task M2: `format()` — JPY (0 decimals)

**Files:**
- Modify: `test/unit/utils/money_formatter_test.dart`

- [ ] **Step 1: Add failing test cases**

Append inside the existing `group('MoneyFormatter.format — USD', ...)` block, then add a new group:

```dart
const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');

group('MoneyFormatter.format — JPY (zero-decimal)', () {
  test('M05: 1_234_567 minor units in en_US renders ¥1,234,567', () {
    expect(
      MoneyFormatter.format(
        amountMinorUnits: 1234567,
        currency: _jpy,
        locale: 'en_US',
      ),
      '¥1,234,567',
    );
  });
});
```

- [ ] **Step 2: Run — expect PASS**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: PASS (2 tests). The minimal implementation from Task M1 already covers zero-decimal input because `NumberFormat.currency` respects `decimalDigits: 0`.

- [ ] **Step 3: Commit**

```bash
git add test/unit/utils/money_formatter_test.dart
git commit -m "test(core): money_formatter JPY zero-decimal coverage"
```

---

### Task M3: `format()` — TWD under zh_TW

**Files:**
- Modify: `test/unit/utils/money_formatter_test.dart`

- [ ] **Step 1: Add failing test**

```dart
const _twd = Currency(code: 'TWD', decimals: 2, symbol: r'NT$');

group('MoneyFormatter.format — TWD in zh_TW', () {
  test('M08: 1_234_567 minor units in zh_TW renders NT\$12,345.67', () {
    expect(
      MoneyFormatter.format(
        amountMinorUnits: 1234567,
        currency: _twd,
        locale: 'zh_TW',
      ),
      r'NT$12,345.67',
    );
  });
});
```

- [ ] **Step 2: Run — expect PASS**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: PASS (3 tests).

- [ ] **Step 3: Commit**

```bash
git add test/unit/utils/money_formatter_test.dart
git commit -m "test(core): money_formatter TWD zh_TW grouping"
```

---

### Task M4: `format()` — CNY under zh_CN

**Files:**
- Modify: `test/unit/utils/money_formatter_test.dart`

- [ ] **Step 1: Add failing test**

```dart
const _cny = Currency(code: 'CNY', decimals: 2, symbol: '¥');

group('MoneyFormatter.format — CNY in zh_CN', () {
  test('M10: 123_456_789 minor units in zh_CN renders ¥1,234,567.89', () {
    expect(
      MoneyFormatter.format(
        amountMinorUnits: 123456789,
        currency: _cny,
        locale: 'zh_CN',
      ),
      '¥1,234,567.89',
    );
  });
});
```

- [ ] **Step 2: Run — expect PASS**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: PASS (4 tests).

- [ ] **Step 3: Commit**

```bash
git add test/unit/utils/money_formatter_test.dart
git commit -m "test(core): money_formatter CNY zh_CN grouping"
```

---

### Task M5: `format()` — ETH 18 decimals + symbol fallback

**Files:**
- Modify: `test/unit/utils/money_formatter_test.dart`

- [ ] **Step 1: Add failing tests**

```dart
const _eth = Currency(code: 'ETH', decimals: 18, isToken: true);

group('MoneyFormatter.format — ETH (18 decimals, no symbol)', () {
  test('M11: 1.5 ETH renders with code fallback', () {
    expect(
      MoneyFormatter.format(
        amountMinorUnits: 1500000000000000000,
        currency: _eth,
        locale: 'en_US',
      ),
      'ETH1.500000000000000000',
    );
  });

  test('M12: 0 ETH renders with full 18 trailing zeros', () {
    expect(
      MoneyFormatter.format(
        amountMinorUnits: 0,
        currency: _eth,
        locale: 'en_US',
      ),
      'ETH0.000000000000000000',
    );
  });
});
```

- [ ] **Step 2: Run — likely FAIL on precision**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: FAIL. `double` cannot represent 18 decimal digits exactly — `1500000000000000000 / 1e18 == 1.5` is true but `NumberFormat.currency(decimalDigits: 18)` may emit `1.500000000000000000` or drift by a ULP. If red, proceed to Step 3; if unexpectedly green, proceed to Step 4.

- [ ] **Step 3: Fix implementation to use `BigInt` splitting for high-decimal currencies**

Edit `lib/core/utils/money_formatter.dart` — replace `format` with a two-path implementation:

```dart
static String format({
  required int amountMinorUnits,
  required Currency currency,
  required String locale,
}) {
  final symbol = currency.symbol ?? currency.code;
  // Double is safe up to ~15 significant digits. Above that, do string
  // arithmetic with BigInt to avoid ULP drift.
  if (currency.decimals <= 12) {
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: currency.decimals,
    );
    return fmt.format(amountMinorUnits / _scale(currency.decimals));
  }
  return _formatHighPrecision(
    amountMinorUnits: amountMinorUnits,
    currency: currency,
    locale: locale,
    symbol: symbol,
  );
}

static String _formatHighPrecision({
  required int amountMinorUnits,
  required Currency currency,
  required String locale,
  required String symbol,
}) {
  final isNeg = amountMinorUnits < 0;
  final abs = BigInt.from(amountMinorUnits).abs();
  final scale = BigInt.from(10).pow(currency.decimals);
  final whole = abs ~/ scale;
  final frac = (abs % scale).toString().padLeft(currency.decimals, '0');
  // Locale-aware grouping for the whole part, literal frac part (no
  // locale-specific decimal separator for the fractional tail — the
  // decimal point is taken from the locale's symbols).
  final wholeFormatted = NumberFormat.decimalPattern(locale).format(whole.toInt());
  // Re-group using BigInt string when `whole` exceeds int range.
  final wholeStr = whole.bitLength <= 53
      ? wholeFormatted
      : _groupBigIntDecimal(whole, locale);
  final decSep = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
  final body = '$wholeStr$decSep$frac';
  return isNeg ? '-$symbol$body' : '$symbol$body';
}

static String _groupBigIntDecimal(BigInt v, String locale) {
  final groupSep = NumberFormat.decimalPattern(locale).symbols.GROUP_SEP;
  final digits = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(groupSep);
    buf.write(digits[i]);
  }
  return buf.toString();
}
```

Keep `_scale` for the low-decimal path.

- [ ] **Step 4: Re-run — expect PASS**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: PASS (6 tests). If M11/M12 still fail, the locale symbol lookup returned a non-`.` decimal separator — inspect the actual output and align (`en_US` must give `.`).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/money_formatter.dart test/unit/utils/money_formatter_test.dart
git commit -m "feat(core): money_formatter BigInt path for high-decimal (ETH 18)"
```

---

### Task M6: `format()` — zero and negative for every currency

**Files:**
- Modify: `test/unit/utils/money_formatter_test.dart`

- [ ] **Step 1: Add the remaining `format` cases**

```dart
group('MoneyFormatter.format — zero / negative', () {
  test('M01: USD 0 → \$0.00', () {
    expect(
      MoneyFormatter.format(amountMinorUnits: 0, currency: _usd, locale: 'en_US'),
      r'$0.00',
    );
  });
  test('M03: USD -12345 → -\$123.45', () {
    expect(
      MoneyFormatter.format(amountMinorUnits: -12345, currency: _usd, locale: 'en_US'),
      r'-$123.45',
    );
  });
  test('M04: JPY 0 → ¥0', () {
    expect(
      MoneyFormatter.format(amountMinorUnits: 0, currency: _jpy, locale: 'en_US'),
      '¥0',
    );
  });
  test('M06: JPY -1_234_567 → -¥1,234,567', () {
    expect(
      MoneyFormatter.format(amountMinorUnits: -1234567, currency: _jpy, locale: 'en_US'),
      '-¥1,234,567',
    );
  });
  test('M07: TWD 0 in zh_TW → NT\$0.00', () {
    expect(
      MoneyFormatter.format(amountMinorUnits: 0, currency: _twd, locale: 'zh_TW'),
      r'NT$0.00',
    );
  });
  test('M09: TWD -1_234_567 in zh_TW → -NT\$12,345.67', () {
    expect(
      MoneyFormatter.format(amountMinorUnits: -1234567, currency: _twd, locale: 'zh_TW'),
      r'-NT$12,345.67',
    );
  });
  test('M13: ETH -1.5 → -ETH1.500000000000000000', () {
    expect(
      MoneyFormatter.format(
        amountMinorUnits: -1500000000000000000,
        currency: _eth,
        locale: 'en_US',
      ),
      '-ETH1.500000000000000000',
    );
  });
});
```

- [ ] **Step 2: Run — expect PASS**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: PASS (13 tests total).

- [ ] **Step 3: Commit**

```bash
git add test/unit/utils/money_formatter_test.dart
git commit -m "test(core): money_formatter zero / negative matrix (USD JPY TWD ETH)"
```

---

### Task M7: `formatSigned()`

**Files:**
- Modify: `test/unit/utils/money_formatter_test.dart`
- Modify: `lib/core/utils/money_formatter.dart`

- [ ] **Step 1: Write failing tests**

```dart
group('MoneyFormatter.formatSigned — PRD 491 list rendering', () {
  test('M14: positive USD → +\$123.45', () {
    expect(
      MoneyFormatter.formatSigned(
        amountMinorUnits: 12345, currency: _usd, locale: 'en_US',
      ),
      r'+$123.45',
    );
  });
  test('M15: negative USD → -\$123.45 (preserve locale-native -)', () {
    expect(
      MoneyFormatter.formatSigned(
        amountMinorUnits: -12345, currency: _usd, locale: 'en_US',
      ),
      r'-$123.45',
    );
  });
  test('M16: zero USD → \$0.00 (no sign)', () {
    expect(
      MoneyFormatter.formatSigned(
        amountMinorUnits: 0, currency: _usd, locale: 'en_US',
      ),
      r'$0.00',
    );
  });
});
```

- [ ] **Step 2: Run — expect FAIL**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: FAIL with "method 'formatSigned' isn't defined".

- [ ] **Step 3: Implement**

Add to `MoneyFormatter`:

```dart
static String formatSigned({
  required int amountMinorUnits,
  required Currency currency,
  required String locale,
}) {
  final base = format(
    amountMinorUnits: amountMinorUnits,
    currency: currency,
    locale: locale,
  );
  if (amountMinorUnits > 0) return '+$base';
  return base; // negatives already carry '-', zero stays bare.
}
```

- [ ] **Step 4: Run — expect PASS**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: PASS (16 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/money_formatter.dart test/unit/utils/money_formatter_test.dart
git commit -m "feat(core): money_formatter formatSigned (+/-) for Home list"
```

---

### Task M8: `formatBare()`

**Files:**
- Modify: `test/unit/utils/money_formatter_test.dart`
- Modify: `lib/core/utils/money_formatter.dart`

- [ ] **Step 1: Write failing tests**

```dart
group('MoneyFormatter.formatBare — no symbol', () {
  test('M17: JPY 1_234_567 en_US → 1,234,567', () {
    expect(
      MoneyFormatter.formatBare(
        amountMinorUnits: 1234567, currency: _jpy, locale: 'en_US',
      ),
      '1,234,567',
    );
  });
  test('M18: USD 12345 zh_CN → 123.45', () {
    expect(
      MoneyFormatter.formatBare(
        amountMinorUnits: 12345, currency: _usd, locale: 'zh_CN',
      ),
      '123.45',
    );
  });
});
```

- [ ] **Step 2: Run — expect FAIL**

Expected: FAIL with "method 'formatBare' isn't defined".

- [ ] **Step 3: Implement**

```dart
static String formatBare({
  required int amountMinorUnits,
  required Currency currency,
  required String locale,
}) {
  if (currency.decimals <= 12) {
    final fmt = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: currency.decimals,
    );
    return fmt.format(amountMinorUnits / _scale(currency.decimals));
  }
  // High-precision: reuse the BigInt path but strip the symbol.
  final full = _formatHighPrecision(
    amountMinorUnits: amountMinorUnits,
    currency: currency,
    locale: locale,
    symbol: '',
  );
  return full.replaceFirst(RegExp(r'^-'), '').startsWith(full)
      ? full
      : full; // symbol was '' — nothing to strip.
}
```

- [ ] **Step 4: Run — expect PASS**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: PASS (18 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/money_formatter.dart test/unit/utils/money_formatter_test.dart
git commit -m "feat(core): money_formatter formatBare (no symbol)"
```

---

### Task M9: `parseToMinorUnits()` — happy paths

**Files:**
- Modify: `test/unit/utils/money_formatter_test.dart`
- Modify: `lib/core/utils/money_formatter.dart`

- [ ] **Step 1: Write failing tests**

```dart
group('MoneyFormatter.parseToMinorUnits — happy path', () {
  test('M19: "123.45" USD en_US → 12345', () {
    expect(
      MoneyFormatter.parseToMinorUnits(
        input: '123.45', currency: _usd, locale: 'en_US',
      ),
      12345,
    );
  });
  test('M20: "1234" JPY en_US → 1234', () {
    expect(
      MoneyFormatter.parseToMinorUnits(
        input: '1234', currency: _jpy, locale: 'en_US',
      ),
      1234,
    );
  });
  test('M21: "1,234.56" USD zh_CN → 123456', () {
    expect(
      MoneyFormatter.parseToMinorUnits(
        input: '1,234.56', currency: _usd, locale: 'zh_CN',
      ),
      123456,
    );
  });
});
```

- [ ] **Step 2: Run — expect FAIL**

Expected: FAIL with "method 'parseToMinorUnits' isn't defined".

- [ ] **Step 3: Implement**

```dart
static int parseToMinorUnits({
  required String input,
  required Currency currency,
  required String locale,
}) {
  final symbols = NumberFormat.decimalPattern(locale).symbols;
  // Strip grouping separators; retain the decimal separator as '.'.
  final normalized = input
      .replaceAll(symbols.GROUP_SEP, '')
      .replaceAll(symbols.DECIMAL_SEP, '.');
  final parts = normalized.split('.');
  if (parts.length > 2 || parts.first.isEmpty && parts.length == 1) {
    throw FormatException('Unparseable amount: "$input"');
  }
  final whole = parts[0].isEmpty ? '0' : parts[0];
  final frac = parts.length == 2 ? parts[1] : '';
  if (frac.length > currency.decimals) {
    throw FormatException(
      'Fractional digits (${frac.length}) exceed '
      '${currency.code}.decimals (${currency.decimals}): "$input"',
    );
  }
  final padded = frac.padRight(currency.decimals, '0');
  final combined = '$whole$padded';
  final parsed = int.tryParse(combined);
  if (parsed == null) {
    throw FormatException('Unparseable amount: "$input"');
  }
  return parsed;
}
```

- [ ] **Step 4: Run — expect PASS**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: PASS (21 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/money_formatter.dart test/unit/utils/money_formatter_test.dart
git commit -m "feat(core): money_formatter parseToMinorUnits (keypad input)"
```

---

### Task M10: `parseToMinorUnits()` — error paths

**Files:**
- Modify: `test/unit/utils/money_formatter_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
group('MoneyFormatter.parseToMinorUnits — errors', () {
  test('M22: "12.345" with USD (2) throws FormatException', () {
    expect(
      () => MoneyFormatter.parseToMinorUnits(
        input: '12.345', currency: _usd, locale: 'en_US',
      ),
      throwsA(isA<FormatException>()),
    );
  });
  test('M23: "abc" throws FormatException', () {
    expect(
      () => MoneyFormatter.parseToMinorUnits(
        input: 'abc', currency: _usd, locale: 'en_US',
      ),
      throwsA(isA<FormatException>()),
    );
  });
});
```

- [ ] **Step 2: Run — expect PASS**

Run: `flutter test test/unit/utils/money_formatter_test.dart -r expanded`
Expected: PASS (23 tests) — Task M9's implementation already throws. If any test fails, the guard in `_parseToMinorUnits` needs tightening (e.g. `int.tryParse` on `'abc12345'` would succeed without the non-digit check — add `RegExp(r'^-?\d+$')` assertion on `combined`).

- [ ] **Step 3: Commit**

```bash
git add test/unit/utils/money_formatter_test.dart
git commit -m "test(core): money_formatter parse error paths"
```

---

## 6. Tasks — `date_helpers.dart`

### Task D1: `startOfDay` + `isSameDay`

**Files:**
- Create: `test/unit/utils/date_helpers_test.dart`
- Modify: `lib/core/utils/date_helpers.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/unit/utils/date_helpers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ledgerly/core/utils/date_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('zh_TW', null);
    await initializeDateFormatting('zh_CN', null);
  });

  group('DateHelpers.startOfDay / isSameDay', () {
    test('D01: startOfDay strips time', () {
      final dt = DateTime(2026, 4, 21, 14, 37, 58, 123);
      expect(DateHelpers.startOfDay(dt), DateTime(2026, 4, 21));
    });
    test('D02: same calendar day = true', () {
      expect(
        DateHelpers.isSameDay(
          DateTime(2026, 4, 21, 0, 0),
          DateTime(2026, 4, 21, 23, 59),
        ),
        isTrue,
      );
    });
    test('D03: crossing midnight = false', () {
      expect(
        DateHelpers.isSameDay(
          DateTime(2026, 4, 21, 23, 59),
          DateTime(2026, 4, 22, 0, 1),
        ),
        isFalse,
      );
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

Run: `flutter test test/unit/utils/date_helpers_test.dart -r expanded`
Expected: FAIL — `DateHelpers` symbol undefined (stub file has only comments).

- [ ] **Step 3: Implement minimal**

Overwrite `lib/core/utils/date_helpers.dart`:

```dart
// lib/core/utils/date_helpers.dart
import 'package:intl/intl.dart';

/// Day-boundary math + locale-aware date formatting (PRD.md 510-552,
/// 864-887). No Flutter imports, no state.
class DateHelpers {
  const DateHelpers._();

  static DateTime startOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
```

- [ ] **Step 4: Run — expect PASS**

Run: `flutter test test/unit/utils/date_helpers_test.dart -r expanded`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/date_helpers.dart test/unit/utils/date_helpers_test.dart
git commit -m "feat(core): date_helpers startOfDay / isSameDay"
```

---

### Task D2: `daysBetween` (including DST resilience)

**Files:**
- Modify: `test/unit/utils/date_helpers_test.dart`
- Modify: `lib/core/utils/date_helpers.dart`

- [ ] **Step 1: Write failing tests**

```dart
group('DateHelpers.daysBetween', () {
  test('D04: forward 5 days', () {
    expect(
      DateHelpers.daysBetween(DateTime(2026, 4, 21), DateTime(2026, 4, 26)),
      5,
    );
  });
  test('D05: backward -5 days', () {
    expect(
      DateHelpers.daysBetween(DateTime(2026, 4, 26), DateTime(2026, 4, 21)),
      -5,
    );
  });
  test('D06: same day, different times → 0', () {
    expect(
      DateHelpers.daysBetween(
        DateTime(2026, 4, 21, 9, 0),
        DateTime(2026, 4, 21, 23, 30),
      ),
      0,
    );
  });
  test('D07: DST-spanning 2 days is 2, not 1 or 3 (PRD 510-552)', () {
    // 2026-03-08 is US DST start. Using noon on either side avoids any
    // accidental nearness to the 02:00 → 03:00 skip.
    expect(
      DateHelpers.daysBetween(
        DateTime(2026, 3, 7, 12, 0),
        DateTime(2026, 3, 9, 12, 0),
      ),
      2,
    );
  });
});
```

- [ ] **Step 2: Run — expect FAIL**

Expected: FAIL — `daysBetween` undefined.

- [ ] **Step 3: Implement (DST-safe via date-only subtraction)**

Add to `DateHelpers`:

```dart
static int daysBetween(DateTime from, DateTime to) {
  // `Duration.inDays` is wrong across DST — it uses absolute hours.
  // We operate on local-midnight anchors and difference in UTC ms to
  // sidestep zone transitions entirely.
  final a = startOfDay(from).toUtc().millisecondsSinceEpoch;
  final b = startOfDay(to).toUtc().millisecondsSinceEpoch;
  const msPerDay = 86400000;
  // `startOfDay` returns a local DateTime; converting to UTC normalizes
  // around the zone's current offset, which is identical for both
  // operands on the same side of a DST transition. Across a transition
  // the offsets differ by ±3600000 ms, so we round-to-nearest-day.
  final diffMs = b - a;
  final rounded = (diffMs / msPerDay).round();
  return rounded;
}
```

- [ ] **Step 4: Run — expect PASS**

Run: `flutter test test/unit/utils/date_helpers_test.dart -r expanded`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/date_helpers.dart test/unit/utils/date_helpers_test.dart
git commit -m "feat(core): date_helpers daysBetween (DST-safe)"
```

---

### Task D3: `daysSince` (splash counter)

**Files:**
- Modify: `test/unit/utils/date_helpers_test.dart`
- Modify: `lib/core/utils/date_helpers.dart`

- [ ] **Step 1: Write failing tests**

```dart
group('DateHelpers.daysSince — splash counter (PRD 510-552)', () {
  test('D08: startDate == today → 0', () {
    expect(
      DateHelpers.daysSince(
        startDate: DateTime(2026, 4, 21),
        now: DateTime(2026, 4, 21, 23, 59),
      ),
      0,
    );
  });
  test('D09: start 10 days ago → 10', () {
    expect(
      DateHelpers.daysSince(
        startDate: DateTime(2026, 4, 11),
        now: DateTime(2026, 4, 21),
      ),
      10,
    );
  });
  test('D10: start 9 days in the future → -9 (no clamp)', () {
    expect(
      DateHelpers.daysSince(
        startDate: DateTime(2026, 4, 30),
        now: DateTime(2026, 4, 21),
      ),
      -9,
    );
  });
});
```

- [ ] **Step 2: Run — expect FAIL**

Expected: FAIL — `daysSince` undefined.

- [ ] **Step 3: Implement**

```dart
static int daysSince({required DateTime startDate, required DateTime now}) =>
    daysBetween(startDate, now);
```

- [ ] **Step 4: Run — expect PASS**

Run: `flutter test test/unit/utils/date_helpers_test.dart -r expanded`
Expected: PASS (10 tests).

**Documented behavior:** negative values are intentional — the UI renders them literally (`-9`). PRD does not specify clamping; this plan freezes the non-clamping behavior so Splash UI (M5) can rely on it.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/date_helpers.dart test/unit/utils/date_helpers_test.dart
git commit -m "feat(core): date_helpers daysSince (splash counter, unclamped)"
```

---

### Task D4: `formatDisplayDate` across locales

**Files:**
- Modify: `test/unit/utils/date_helpers_test.dart`
- Modify: `lib/core/utils/date_helpers.dart`

- [ ] **Step 1: Write failing tests**

```dart
group('DateHelpers.formatDisplayDate — splash date (PRD 525, 549)', () {
  final d = DateTime(2026, 4, 21);
  test('D11: en_US → "Apr 21, 2026"', () {
    expect(DateHelpers.formatDisplayDate(d, 'en_US'), 'Apr 21, 2026');
  });
  test('D12: zh_TW → "2026年4月21日"', () {
    expect(DateHelpers.formatDisplayDate(d, 'zh_TW'), '2026年4月21日');
  });
  test('D13: zh_CN → "2026年4月21日"', () {
    expect(DateHelpers.formatDisplayDate(d, 'zh_CN'), '2026年4月21日');
  });
});
```

- [ ] **Step 2: Run — expect FAIL**

Expected: FAIL — method undefined.

- [ ] **Step 3: Implement**

```dart
static String formatDisplayDate(DateTime date, String locale) =>
    DateFormat.yMMMd(locale).format(date);
```

- [ ] **Step 4: Run — expect PASS**

Run: `flutter test test/unit/utils/date_helpers_test.dart -r expanded`
Expected: PASS (13 tests). If zh_TW / zh_CN emit a different canonical string, align the test to `DateFormat.yMMMd` output — check with a quick REPL: the ICU canonical for zh_TW `yMMMd` is `y年M月d日`.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/date_helpers.dart test/unit/utils/date_helpers_test.dart
git commit -m "feat(core): date_helpers formatDisplayDate (splash / settings)"
```

---

### Task D5: `formatDayHeader`

**Files:**
- Modify: `test/unit/utils/date_helpers_test.dart`
- Modify: `lib/core/utils/date_helpers.dart`

- [ ] **Step 1: Write failing tests**

```dart
group('DateHelpers.formatDayHeader — Home list (PRD 881-882)', () {
  final d = DateTime(2026, 4, 21); // Tuesday
  test('D14: en_US format starts with weekday abbrev', () {
    final s = DateHelpers.formatDayHeader(d, 'en_US');
    expect(s, contains('Apr'));
    expect(s, contains('21'));
    expect(s, anyOf(startsWith('Tue'), startsWith('Mon')));
    // 2026-04-21 is a Tuesday; assert exactly:
    expect(s, 'Tue, Apr 21');
  });
  test('D15: zh_TW format contains 4月21日', () {
    final s = DateHelpers.formatDayHeader(d, 'zh_TW');
    expect(s, contains('4月21日'));
  });
});
```

- [ ] **Step 2: Run — expect FAIL**

Expected: FAIL — method undefined.

- [ ] **Step 3: Implement**

```dart
static String formatDayHeader(DateTime date, String locale) =>
    DateFormat.MMMEd(locale).format(date);
```

(`DateFormat.MMMEd` = `E, MMM d` → `Tue, Apr 21` in en_US. In zh_TW / zh_CN it emits `M月d日 E` which satisfies the `contains('4月21日')` assertion.)

- [ ] **Step 4: Run — expect PASS**

Run: `flutter test test/unit/utils/date_helpers_test.dart -r expanded`
Expected: PASS (15 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/date_helpers.dart test/unit/utils/date_helpers_test.dart
git commit -m "feat(core): date_helpers formatDayHeader (Home day buckets)"
```

---

### Task D6: `formatShortDate`

**Files:**
- Modify: `test/unit/utils/date_helpers_test.dart`
- Modify: `lib/core/utils/date_helpers.dart`

- [ ] **Step 1: Write failing tests**

```dart
group('DateHelpers.formatShortDate', () {
  final d = DateTime(2026, 4, 21);
  test('D16: en_US → 4/21/2026', () {
    expect(DateHelpers.formatShortDate(d, 'en_US'), '4/21/2026');
  });
  test('D17: zh_CN → 2026/4/21', () {
    expect(DateHelpers.formatShortDate(d, 'zh_CN'), '2026/4/21');
  });
});
```

- [ ] **Step 2: Run — expect FAIL**

Expected: FAIL — method undefined.

- [ ] **Step 3: Implement**

```dart
static String formatShortDate(DateTime date, String locale) =>
    DateFormat.yMd(locale).format(date);
```

- [ ] **Step 4: Run — expect PASS**

Run: `flutter test test/unit/utils/date_helpers_test.dart -r expanded`
Expected: PASS (17 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/date_helpers.dart test/unit/utils/date_helpers_test.dart
git commit -m "feat(core): date_helpers formatShortDate"
```

---

### Task D7: `applySplashTemplate` — basics

**Files:**
- Modify: `test/unit/utils/date_helpers_test.dart`
- Modify: `lib/core/utils/date_helpers.dart`

- [ ] **Step 1: Write failing tests**

```dart
group('DateHelpers.applySplashTemplate — PRD 526/549-551', () {
  test('D18: default "Since {date}" template', () {
    expect(
      DateHelpers.applySplashTemplate(
        template: 'Since {date}',
        startDate: DateTime(2026, 4, 11),
        now: DateTime(2026, 4, 21),
        locale: 'en_US',
      ),
      'Since Apr 11, 2026',
    );
  });
  test('D19: {days} + {date}', () {
    expect(
      DateHelpers.applySplashTemplate(
        template: '{days} days since {date}',
        startDate: DateTime(2026, 4, 11),
        now: DateTime(2026, 4, 21),
        locale: 'en_US',
      ),
      '10 days since Apr 11, 2026',
    );
  });
  test('D20: {days} at zero', () {
    expect(
      DateHelpers.applySplashTemplate(
        template: '{days} days since {date}',
        startDate: DateTime(2026, 4, 21),
        now: DateTime(2026, 4, 21),
        locale: 'en_US',
      ),
      '0 days since Apr 21, 2026',
    );
  });
});
```

- [ ] **Step 2: Run — expect FAIL**

Expected: FAIL — method undefined.

- [ ] **Step 3: Implement**

```dart
static String applySplashTemplate({
  required String template,
  required DateTime startDate,
  required DateTime now,
  required String locale,
}) {
  final days = daysSince(startDate: startDate, now: now);
  final daysStr = NumberFormat.decimalPattern(locale).format(days);
  final dateStr = formatDisplayDate(startDate, locale);
  return template
      .replaceAll('{days}', daysStr)
      .replaceAll('{date}', dateStr);
}
```

- [ ] **Step 4: Run — expect PASS**

Run: `flutter test test/unit/utils/date_helpers_test.dart -r expanded`
Expected: PASS (20 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/date_helpers.dart test/unit/utils/date_helpers_test.dart
git commit -m "feat(core): date_helpers applySplashTemplate ({days}, {date})"
```

---

### Task D8: `applySplashTemplate` — edge cases

**Files:**
- Modify: `test/unit/utils/date_helpers_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
group('DateHelpers.applySplashTemplate — edges', () {
  test('D21: negative {days} passes through as "-9"', () {
    expect(
      DateHelpers.applySplashTemplate(
        template: '{days} days since {date}',
        startDate: DateTime(2026, 4, 30),
        now: DateTime(2026, 4, 21),
        locale: 'en_US',
      ),
      '-9 days since Apr 30, 2026',
    );
  });
  test('D22: unknown placeholder passes through unchanged', () {
    expect(
      DateHelpers.applySplashTemplate(
        template: '{foo} is kept and {days} {date}',
        startDate: DateTime(2026, 4, 11),
        now: DateTime(2026, 4, 21),
        locale: 'en_US',
      ),
      '{foo} is kept and 10 Apr 11, 2026',
    );
  });
  test('D23: large {days} uses locale grouping', () {
    // 2000-04-21 → 2026-04-21 is 26 × 365 + 7 leap days = 9497 days.
    expect(
      DateHelpers.applySplashTemplate(
        template: '{days}',
        startDate: DateTime(2000, 4, 21),
        now: DateTime(2026, 4, 21),
        locale: 'en_US',
      ),
      '9,497',
    );
  });
});
```

- [ ] **Step 2: Run — expect PASS**

Run: `flutter test test/unit/utils/date_helpers_test.dart -r expanded`
Expected: PASS (23 tests) — the Task D7 implementation already handles all three. If D22 fails because `String.replaceAll` happens to hit `{foo}`, verify the implementation only replaces the two known tokens (it does).

If D23 fails because the computed day count differs by ±1 from the expected 9,497 (leap-year edge), recompute by hand from the actual Dart `DateTime` arithmetic and update the expectation. Do **not** change the implementation — the assertion tests locale grouping, not leap-year counting.

- [ ] **Step 3: Commit**

```bash
git add test/unit/utils/date_helpers_test.dart
git commit -m "test(core): date_helpers template edge cases (negative, unknown, grouping)"
```

---

## 7. Task G: Pre-merge grep + exit-criteria sweep

**Files:** none (verification only)

- [ ] **Step 1: Run money-is-int grep (Guardrail G4)**

```bash
rg 'double\s+\w*(amount|balance|rate|price)' lib/
```

Expected output: **zero matches**. `lib/core/utils/money_formatter.dart` declares `double _scale(int)` and a local `final scaled = amountMinorUnits / _scale(...)`, neither of which matches the pattern (`scaled` is a `double` named literally `scaled`, not `amount|balance|rate|price`). If the grep flags anything, rename the offending local — do not loosen the grep.

- [ ] **Step 2: Run full analyzer**

```bash
flutter analyze
```

Expected: no errors, no warnings. If `intl`-related hints appear, they are already present repo-wide and unrelated to this stream.

- [ ] **Step 3: Run full utility test suite**

```bash
flutter test test/unit/utils/ -r expanded
```

Expected: 46 tests pass total (23 money + 23 date).

- [ ] **Step 4: Confirm public API vs §1 contract**

Visually diff `lib/core/utils/money_formatter.dart` and `lib/core/utils/date_helpers.dart` against §1.1 / §1.2. Every listed signature must be present, non-private, `static`, and unchanged in parameter names / types. Private helpers (`_scale`, `_formatHighPrecision`, `_groupBigIntDecimal`) are allowed in addition; new public symbols are not (downstream M3/M5 would be compiling against §1 already).

- [ ] **Step 5: Tag commit boundary**

```bash
git log --oneline -n 20
```

Expected: a coherent series of `feat(core):` / `test(core):` commits, one per task, matching §4's TDD order.

---

## 8. Consumers of this public API (downstream, do not touch in this stream)

These call sites exist only after M3/M5 — this stream must not pre-import from them, but the contract freezes here so they can be built in parallel once M5 unblocks.

| Caller                                             | File (planned)                                            | Method used                                                                                                                            |
|----------------------------------------------------|-----------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| M5 Home summary strip                              | `features/home/home_controller.dart`                      | `MoneyFormatter.format`                                                                                                                |
| M5 Home day list row                               | `features/home/widgets/transaction_tile.dart`             | `MoneyFormatter.formatSigned`                                                                                                          |
| M5 Home day header                                 | `features/home/widgets/day_header.dart`                   | `DateHelpers.formatDayHeader`                                                                                                          |
| M5 Transactions keypad                             | `features/transactions/transaction_form.dart`             | `MoneyFormatter.parseToMinorUnits`                                                                                                     |
| M5 Transactions display                            | `features/transactions/transaction_form.dart`             | `MoneyFormatter.formatBare`                                                                                                            |
| M5 Splash label                                    | `features/splash/splash_screen.dart`                      | `DateHelpers.applySplashTemplate`                                                                                                      |
| M5 Splash rainbow text                             | `features/splash/splash_screen.dart`                      | `DateHelpers.formatDisplayDate`                                                                                                        |
| M5 Accounts balance card                           | `features/accounts/widgets/account_card.dart`             | `MoneyFormatter.format`                                                                                                                |
| M5 Settings date display                           | `features/settings/settings_screen.dart`                  | `DateHelpers.formatDisplayDate`                                                                                                        |
| M3 `TransactionRepository` tests (minor-unit math) | `test/unit/repositories/transaction_repository_test.dart` | *(none — repository tests do not format; formatter tests are the only utility tests)*                                                  |
| M4 `bootstrap.dart`                                | `app/bootstrap.dart`                                      | Calls `initializeDateFormatting(...)` for the active locale + the three MVP locales. Not a direct `DateHelpers` call — a prerequisite. |

**Non-consumer note.** M3 repositories do **not** use `MoneyFormatter`. Their tests work on raw `int amountMinorUnits` — formatting is a UI concern. G3 (controllers own presentation) keeps formatter calls out of widget `build()` methods as well; M5 controllers map state → pre-formatted strings.

---

## 9. Exit criteria (maps to `implementation-plan.md` §5 M2)

Stream A is done when **all** hold:

1. `lib/core/utils/money_formatter.dart` implements the §1.1 contract, full replacement of the M0 stub.
2. `lib/core/utils/date_helpers.dart` implements the §1.2 contract, full replacement of the M0 stub.
3. `test/unit/utils/money_formatter_test.dart` covers **4 currencies × {positive, negative, zero}** per implementation-plan §5 M2 exit criteria — verified by rows M01–M13 in §2.1.
4. `test/unit/utils/date_helpers_test.dart` covers day-boundary math across locales per implementation-plan §5 M2 — verified by rows D01–D17 in §2.2.
5. Splash day-count helper test lands per `PRD.md` line 956 — verified by rows D08–D10 and D18–D23.
6. `flutter test test/unit/utils/ -r expanded` — 46 passing tests, zero failures.
7. `flutter analyze` — clean.
8. Guardrail **G4 grep** — `rg 'double\s+\w*(amount|balance|rate|price)' lib/` returns zero hits. `money_formatter.dart` does not trip it because the local `double` intermediate is named `scaled`, not `amount`/`balance`/`rate`/`price`.
9. `pubspec.yaml` unchanged (no new deps — `intl ^0.20.2` already present from M0).
10. Every public method listed in §1 matches its final implementation signature **character-for-character** (parameter names, types, optionality). This is what M3 and M5 code compiled against during parallel development relies on.

---

## 10. Risks & mitigations

| Risk                                                                                                         | Likelihood              | Mitigation                                                                                                                                                                        |
|--------------------------------------------------------------------------------------------------------------|-------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `double` rounding at 18 decimals (ETH) produces off-by-ULP output                                            | High without guard      | Task M5 switches to `BigInt` path for `decimals > 12`. Test row M11 asserts the exact 18-digit string.                                                                            |
| `DateFormat` throws "Locale data has not been initialized" in tests                                          | Medium                  | `setUpAll` calls `initializeDateFormatting` for all three MVP locales. Documented in §2.3. Production init is M4's `bootstrap.dart` concern.                                      |
| `Duration.inDays` mis-counts across DST                                                                      | Medium                  | `daysBetween` uses `startOfDay(...).toUtc().millisecondsSinceEpoch` with `round()`, not `.inDays`. Test D07 asserts the DST-crossing case.                                        |
| Freezed `Currency` field-name drift from the M1 contract                                                     | Low (M1 already merged) | §11 re-verifies at plan time; task M1 imports the real `Currency` and will fail to compile if field names ever change.                                                            |
| `intl 0.20.2` behavior differs from `0.19.x` on canonical `yMMMd` zh_TW output (`2026年4月21日` vs `2026/4/21`) | Low                     | Test D12/D13 assert the exact string. If `intl` ever updates the CLDR snapshot and the assertion drifts, the test is the tripwire — update the expectation and document the bump. |
| Negative splash day count surprises downstream UI                                                            | Low                     | Contract § D3 freezes "negative is valid, UI decides presentation". Splash widget (M5) documents this in its own plan.                                                            |
| `parseToMinorUnits` silently truncates trailing zeros (`"1.2"` in USD → 120? or 12?)                         | Medium                  | Implementation right-pads the fractional part with zeros to `decimals`. `"1.2"` in USD → `120` minor units (= `$1.20`). Documented in Task M9 Step 3.                             |
| Locale `zh_CN` vs `zh` fallback chain in `intl`                                                              | Low                     | CLAUDE.md explicitly requires a base `app_zh.arb`; `intl` date/number data for both `zh_CN` and `zh_TW` ships in the package and initializes independently.                       |

---

## 11. Upstream M1 dependency verification (do this before Task M1)

Before the first commit of this stream, re-verify:

```bash
git log --oneline lib/data/models/currency.dart | head -5
cat lib/data/models/currency.dart
```

Expected content of `lib/data/models/currency.dart` (already verified at plan-authoring time 2026-04-21):

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'currency.freezed.dart';

@freezed
abstract class Currency with _$Currency {
  const factory Currency({
    required String code,
    required int decimals,
    String? symbol,
    String? nameL10nKey,
    @Default(false) bool isToken,
    int? sortOrder,
  }) = _Currency;
}
```

Required fields for this stream: `code`, `decimals`, `symbol`. All three are present and typed as §1.1 expects. If M1 ever renames `decimals` or `symbol`, **stop** — field-name drift breaks §1.1 and the test matrix; coordinate a synchronized bump with the M1 owner before continuing.

Also confirm the generated `currency.freezed.dart` exists (committed at M1 merge). If missing:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 12. Self-review (run before declaring complete)

**Spec coverage vs prompt / PRD:**
- [x] `money_formatter.dart` format for integer minor units + `Currency` + locale — §1.1 `format`, Tasks M1-M6.
- [x] USD (2), JPY (0), TWD (2), ETH (18) — §2.1 matrix rows M01-M13.
- [x] Positive / negative / zero per currency — §2.1 M01-M13.
- [x] Sign handling for Home `+`/`-` (PRD 491) — §1.1 `formatSigned`, Task M7.
- [x] `date_helpers.dart` day-boundary math — §1.2 `startOfDay`/`isSameDay`/`daysBetween`, Tasks D1-D2.
- [x] Splash day counter (PRD 510-552) — §1.2 `daysSince`, Task D3.
- [x] Locale-aware date formatting — §1.2 `formatDisplayDate`/`formatDayHeader`/`formatShortDate`, Tasks D4-D6.
- [x] `{days}` / `{date}` template substitution (PRD 526) — §1.2 `applySplashTemplate`, Tasks D7-D8.
- [x] Tests in `test/unit/utils/` — created in Tasks M1 and D1.
- [x] At least 4 currencies × {+,−,0} — §2.1 M01-M13 = 4 × 3 = 12 core cases plus extras.
- [x] Day boundary across locales — D11-D17 cover en_US / zh_TW / zh_CN; D07 covers DST.
- [x] `startDate == today` → 0 — D08.
- [x] `startDate > today` — D10 documents behavior as **negative integer, no clamp**.
- [x] Pre-merge grep assertion (G4) — §7 Task G Step 1.
- [x] Public API contract declared up-front — §1.
- [x] Consumers listed — §8.
- [x] Exit criteria mapped to implementation-plan §5 M2 — §9.

**Placeholder scan:** grep this plan for `TBD`, `TODO`, `implement later`, `similar to task`, `fill in`. Expected: zero hits. If the parent agent's copy introduces any, reject the copy.

**Type consistency:** `MoneyFormatter.format` accepts `({required int amountMinorUnits, required Currency currency, required String locale})` in §1.1, Task M1, M5, M6, M7, M8. `DateHelpers.daysSince` accepts `({required DateTime startDate, required DateTime now})` in §1.2, Task D3, D7, D8. Parameter names are stable across all references.

**Signature freeze acknowledgment:** Once this stream merges, M3 repository tests and M5 feature slices will compile against §1. A later signature change is a breaking rebase for every slice. Any post-merge change needs a coordinated PR stack updating every consumer in §8.

---

*Stream A's contract with downstream M3 + M5 is §1. Stream A's exit sign-off is §9. Anything beyond those two seams is scope creep and belongs in Stream B, Stream C, or a later milestone.*
