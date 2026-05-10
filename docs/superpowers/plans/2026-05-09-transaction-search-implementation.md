# Transaction Search Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build memo-based transaction search on the Analysis tab — a two-level drill-down (search results grouped by `(category, currency)` → category detail grouped by date), search-as-you-type with 300ms debounce, and read-only result rows.

**Architecture:** Strict 3-layer (Data → UI). One DAO/repo addition (`watchByMemo`) returns a Drift stream of domain `Transaction`s; an `AnalysisController` (Riverpod `StreamNotifier`, `keepAlive: true`) debounces and groups results, composing live category metadata via a slice-local `analysisCategoriesByIdProvider`; a `CategorySearchDetailController` family handles the drill-down. Search-result rows are pure presentational — no tap, swipe, or overflow menu.

**Tech Stack:** Flutter 3.41.7, Drift (schema v4, no migration), Riverpod with `riverpod_generator`, Freezed sealed unions, `go_router`, ARB-based l10n with ICU plurals.

**Spec:** [`docs/superpowers/specs/2026-05-09-transaction-search-design.md`](../specs/2026-05-09-transaction-search-design.md)

**Memory invariants** (already saved to feedback memory — propagate to any future search-style feature):
- Search results sort by `max(transaction.date)` desc per group (not amount, not currency-bucketed).
- Search-result transaction rows are read-only — build a dedicated row widget; do not reuse Home's `TransactionTile`.

---

## File Map

**New files (analysis slice):**

| Path                                                             | Responsibility                                                             |
|------------------------------------------------------------------|----------------------------------------------------------------------------|
| `lib/features/analysis/analysis_state.dart`                      | Freezed sealed union `AnalysisState` + value class `CategorySearchResult`  |
| `lib/features/analysis/analysis_controller.dart`                 | `StreamNotifier<AnalysisState>` — debounce + grouping                      |
| `lib/features/analysis/analysis_providers.dart`                  | `analysisCategoriesByIdProvider`, `analysisAccountsByIdProvider`           |
| `lib/features/analysis/category_search_detail_state.dart`        | Freezed sealed union `CategorySearchDetailState` + `DatedTransactionGroup` |
| `lib/features/analysis/category_search_detail_controller.dart`   | Family `StreamNotifier` keyed on `(categoryId, query, currencyCode)`       |
| `lib/features/analysis/category_search_detail_screen.dart`       | Drill-down page                                                            |
| `lib/features/analysis/widgets/category_search_tile.dart`        | Level 1 result card                                                        |
| `lib/features/analysis/widgets/transaction_search_row.dart`      | Read-only Level 2 transaction row                                          |
| `lib/features/analysis/widgets/analysis_search_placeholder.dart` | Idle-state prompt                                                          |

**Modified files:**

| Path                                                | Change                                                                           |
|-----------------------------------------------------|----------------------------------------------------------------------------------|
| `lib/data/database/daos/transaction_dao.dart`       | Add `watchByMemo` (with empty-query short-circuit)                               |
| `lib/data/repositories/transaction_repository.dart` | Add `watchByMemo` returning `Stream<List<Transaction>>`                          |
| `lib/features/analysis/analysis_screen.dart`        | Rewrite (SearchBar + state-driven body)                                          |
| `lib/app/router.dart`                               | Add `search/:categoryId` child route under `/analysis` with `q`/`c` guards       |
| `l10n/app_en.arb`                                   | Add 6 keys (see Task 1)                                                          |
| `l10n/app_zh.arb`                                   | Keep the fallback shim untouched except for `appTitle`; do not add Analysis keys |
| `l10n/app_zh_TW.arb`                                | Add same 6 keys                                                                  |
| `l10n/app_zh_CN.arb`                                | Add same 6 keys                                                                  |

**New test files:**

- `test/unit/repositories/transaction_repository_search_test.dart`
- `test/unit/controllers/analysis_controller_test.dart`
- `test/unit/controllers/category_search_detail_controller_test.dart`
- `test/widget/features/analysis/analysis_screen_test.dart`
- `test/widget/features/analysis/category_search_detail_screen_test.dart`

---

## Conventions referenced in this plan

- **Drift in-memory harness** lives at `test/unit/repositories/_harness/test_app_database.dart`. Existing tests (e.g. `transaction_repository_test.dart`) seed via `customStatement` calls. Mirror that pattern.
- **Controller tests** use `mocktail` + `flutter_riverpod` `ProviderContainer` overrides. Mirror `test/unit/controllers/home_controller_test.dart`.
- **Codegen:** every change to a `@freezed` / `@Riverpod` / Drift annotation requires `dart run build_runner build --delete-conflicting-outputs`. The plan flags it explicitly where needed.
- **Format-then-test:** `dart format .` is run before `flutter analyze` and before pushing tests.

---

## Task 1: Add l10n keys

**Files:**
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh_TW.arb`
- Modify: `l10n/app_zh_CN.arb`

The screens we build later reference `l10n.analysisTitle`, `l10n.analysisSearchHint`, etc. Adding them first means later widget tests can resolve copy without falling back to English.

The existing analysis screen uses `l10n.navAnalysis`, `l10n.analysisPlaceholderTitle`, `l10n.analysisPlaceholderBody` — leave those keys in place; we override only the screen body, not the AppBar title key. (The spec uses `analysisTitle` as the new AppBar title. Keep both: `navAnalysis` is the bottom-nav label; `analysisTitle` is the AppBar title — they may have different copy.)

- [x] **Step 1: Add 7 keys to `l10n/app_en.arb`**

Insert into the JSON object (before the closing brace, but valid order doesn't matter for ARB):

```json
"analysisTitle": "Analysis",
"@analysisTitle": {"description": "Analysis tab AppBar title"},

"analysisSearchHint": "Search transactions…",
"@analysisSearchHint": {"description": "SearchBar placeholder on Analysis"},

"analysisSearchPrompt": "Search memos to find past transactions",
"@analysisSearchPrompt": {"description": "Idle-state copy under the search icon"},

"analysisNoResults": "No transactions found",
"@analysisNoResults": {"description": "Empty-state copy when query has no matches"},

"analysisTransactionCount": "{count, plural, =1{{count} transaction} other{{count} transactions}}",
"@analysisTransactionCount": {
  "description": "Count of matching transactions in a category card",
  "placeholders": {"count": {"type": "int", "format": "decimalPattern"}}
},

"analysisSearchTotal": "Total",
"@analysisSearchTotal": {"description": "Header label for the overall sum on the detail page"},

"analysisErrorMessage": "Something went wrong while searching",
"@analysisErrorMessage": {"description": "User-facing error copy when the search stream errors (Drift error, schema corruption, etc.)"}
```

- [x] **Step 2: Leave `l10n/app_zh.arb` as the required fallback shim**

Per the current repo contract (`test/unit/l10n/arb_audit_test.dart` and `AGENTS.md`), `app_zh.arb` must continue to contain exactly one non-metadata key: `appTitle`. Keep the file present so Flutter localizations can resolve the bare `zh` locale, but do not add feature keys there. Analysis-search strings belong only in `app_en.arb`, `app_zh_TW.arb`, and `app_zh_CN.arb`.

- [x] **Step 3: Add 7 keys to `l10n/app_zh_TW.arb`**

```json
"analysisTitle": "分析",
"analysisSearchHint": "搜尋交易紀錄…",
"analysisSearchPrompt": "搜尋備註以尋找過往交易",
"analysisNoResults": "找不到交易紀錄",
"analysisTransactionCount": "{count} 筆交易",
"@analysisTransactionCount": {
  "placeholders": {"count": {"type": "int", "format": "decimalPattern"}}
},
"analysisSearchTotal": "總計",
"analysisErrorMessage": "搜尋時發生錯誤"
```

- [x] **Step 4: Add 7 keys to `l10n/app_zh_CN.arb`**

```json
"analysisTitle": "分析",
"analysisSearchHint": "搜索交易记录…",
"analysisSearchPrompt": "搜索备注以查找过往交易",
"analysisNoResults": "未找到交易记录",
"analysisTransactionCount": "{count} 笔交易",
"@analysisTransactionCount": {
  "placeholders": {"count": {"type": "int", "format": "decimalPattern"}}
},
"analysisSearchTotal": "总计",
"analysisErrorMessage": "搜索时发生错误"
```

- [x] **Step 5: Regenerate l10n bindings**

Run: `flutter pub get`
Expected: regenerates `lib/l10n/app_localizations*.dart`. No errors. `app_zh.arb` must still exist, but it remains the one-key fallback shim.

- [x] **Step 6: Verify keys are codegen'd**

Run: `grep -n "analysisTransactionCount\|analysisSearchPrompt" lib/l10n/app_localizations.dart`
Expected: both keys appear as `String get analysisSearchPrompt;` and `String analysisTransactionCount(int count);`.

- [x] **Step 7: Commit**

```bash
dart format l10n/
git add l10n/ lib/l10n/
git commit -m "feat(l10n): add analysis-search localization keys"
```

---

## Task 2: DAO `watchByMemo`

**Files:**
- Modify: `lib/data/database/daos/transaction_dao.dart`
- Test: `test/unit/repositories/transaction_repository_search_test.dart` (new)

The DAO returns Drift `TransactionRow`s ordered `date DESC, id DESC`. Empty/whitespace queries short-circuit to `Stream.value(const [])` — without it, `LIKE '%%'` matches every memoed row and a deep-linked `/analysis/search/5?q=&c=USD` would dump every USD row in category 5.

- [x] **Step 1: Create the test file with the empty-query test**

Create `test/unit/repositories/transaction_repository_search_test.dart`:

```dart
// Tests for `TransactionDao.watchByMemo` and
// `TransactionRepository.watchByMemo` — analysis-search backing
// streams. Uses the shared in-memory harness; mirrors the seeding
// style of `transaction_repository_test.dart`.

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';

import '_harness/test_app_database.dart';

Future<void> _seedMinimal(AppDatabase db) async {
  await db.customStatement(
    "INSERT INTO currencies (code, decimals, symbol, name_l10n_key, "
    "is_token, sort_order) VALUES ('USD', 2, '\$', 'currency.usd', 0, 1)",
  );
  await db.customStatement(
    "INSERT INTO categories (id, type, l10n_key, custom_name, icon, color, "
    "sort_order, is_archived) VALUES (1, 'expense', 'cat.food', NULL, "
    "'restaurant', 0, 1, 0)",
  );
  await db.customStatement(
    "INSERT INTO account_types (id, l10n_key, icon, color, sort_order, "
    "is_archived) VALUES (1, 'acct.cash', 'wallet', 0, 1, 0)",
  );
  await db.customStatement(
    "INSERT INTO accounts (id, account_type_id, name, currency, "
    "opening_balance_minor_units, sort_order, is_archived) VALUES "
    "(1, 1, 'Cash', 'USD', 0, 1, 0)",
  );
}

Future<void> _insertTx({
  required AppDatabase db,
  required int id,
  required DateTime date,
  String? memo,
}) {
  return db.customStatement(
    "INSERT INTO transactions (id, amount_minor_units, currency, "
    "category_id, account_id, date, memo, created_at, updated_at) "
    "VALUES (?, 1000, 'USD', 1, 1, ?, ?, ?, ?)",
    <Object?>[
      id,
      date.toIso8601String(),
      memo,
      DateTime.utc(2026, 1, 1).toIso8601String(),
      DateTime.utc(2026, 1, 1).toIso8601String(),
    ],
  );
}

void main() {
  group('TransactionDao.watchByMemo', () {
    late AppDatabase db;

    setUp(() async {
      db = newTestAppDatabase();
      await _seedMinimal(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('empty query short-circuits without scanning', () async {
      await _insertTx(
        db: db,
        id: 1,
        date: DateTime.utc(2026, 5, 1),
        memo: 'coffee',
      );

      final empty = await db.transactionDao.watchByMemo('').first;
      final whitespace = await db.transactionDao.watchByMemo('   ').first;

      expect(empty, isEmpty);
      expect(whitespace, isEmpty);
    });
  });
}
```

- [x] **Step 2: Run the test, expect failure (method not defined)**

Run: `flutter test test/unit/repositories/transaction_repository_search_test.dart`
Expected: FAIL — compile error "The method 'watchByMemo' isn't defined for the type 'TransactionDao'."

- [x] **Step 3: Add the DAO method with empty-query short-circuit only**

Open `lib/data/database/daos/transaction_dao.dart`. Add this method after `watchByCategory` (find an analogous `watchBy*` method to anchor it):

```dart
/// Watch transactions whose memo contains [query] (case-insensitive
/// substring), ordered `date DESC, id DESC`. Memos that are NULL are
/// excluded (`isNotNull()` filter; LIKE on NULL never matches anyway).
/// Empty/whitespace queries short-circuit to `[]` — without this,
/// `LIKE '%%'` matches every memoed row and would silently dump the
/// table on a broken deep link.
Stream<List<TransactionRow>> watchByMemo(String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return Stream<List<TransactionRow>>.value(const []);
  }
  final like = '%${trimmed.toLowerCase()}%';
  return (select(transactions)
        ..where((t) => t.memo.isNotNull() & t.memo.lower().like(like))
        ..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
        ]))
      .watch();
}
```

Use the typed query builder (matches every other `watch*` method in this DAO — `watchAll`, `watchByDateRange`, `watchByAccount`, `watchByCategory`, `watchById`). Case-insensitivity is handled via `t.memo.lower().like(...)` against a lowercased pattern, which is identical to `COLLATE NOCASE` for ASCII (the only case-variant alphabet that matters here — Chinese/Japanese have no case). No raw SQL string, no `Variable<String>` import, no manual row-mapping bug to write.

- [x] **Step 4: Run the empty-query test, expect pass**

Run: `flutter test test/unit/repositories/transaction_repository_search_test.dart -p vm`
Expected: PASS (1 test).

- [x] **Step 5: Add the case-insensitive match test**

Append inside the `group('TransactionDao.watchByMemo', ...)`:

```dart
test('case-insensitive substring match; NULL memo excluded', () async {
  await _insertTx(db: db, id: 1, date: DateTime.utc(2026, 5, 1), memo: 'Coffee');
  await _insertTx(db: db, id: 2, date: DateTime.utc(2026, 5, 2), memo: 'COFFEE shop');
  await _insertTx(db: db, id: 3, date: DateTime.utc(2026, 5, 3), memo: 'tea');
  await _insertTx(db: db, id: 4, date: DateTime.utc(2026, 5, 4), memo: null);

  final rows = await db.transactionDao.watchByMemo('coffee').first;

  expect(rows.map((r) => r.id).toSet(), {1, 2});
});
```

- [x] **Step 6: Run all DAO tests, expect pass**

Run: `flutter test test/unit/repositories/transaction_repository_search_test.dart`
Expected: PASS (2 tests).

- [x] **Step 7: Add the ordering test**

Append:

```dart
test('orders by date DESC, id DESC', () async {
  await _insertTx(db: db, id: 1, date: DateTime.utc(2026, 5, 1), memo: 'coffee A');
  await _insertTx(db: db, id: 2, date: DateTime.utc(2026, 5, 3), memo: 'coffee B');
  await _insertTx(db: db, id: 3, date: DateTime.utc(2026, 5, 3), memo: 'coffee C');

  final rows = await db.transactionDao.watchByMemo('coffee').first;

  // 2026-05-03/id=3, 2026-05-03/id=2, 2026-05-01/id=1
  expect(rows.map((r) => r.id).toList(), [3, 2, 1]);
});
```

- [x] **Step 8: Run, expect pass**

Run: `flutter test test/unit/repositories/transaction_repository_search_test.dart`
Expected: PASS (3 tests).

- [x] **Step 9: Commit**

```bash
dart format lib/data/database/daos/transaction_dao.dart \
           test/unit/repositories/transaction_repository_search_test.dart
git add lib/data/database/daos/transaction_dao.dart \
        test/unit/repositories/transaction_repository_search_test.dart
git commit -m "feat(data): add TransactionDao.watchByMemo with empty-query guard"
```

---

## Task 3: Repository `watchByMemo`

**Files:**
- Modify: `lib/data/repositories/transaction_repository.dart`
- Test: `test/unit/repositories/transaction_repository_search_test.dart` (extend)

Returns domain `Transaction`s by delegating to the DAO and reusing the existing `_rowsToDomain` helper.

- [x] **Step 1: Add the repository test**

Append inside `void main()` of `transaction_repository_search_test.dart`, AFTER the existing `group('TransactionDao.watchByMemo', ...)` block:

```dart
group('TransactionRepository.watchByMemo', () {
  late AppDatabase db;
  late TransactionRepository repo;

  setUp(() async {
    db = newTestAppDatabase();
    await _seedMinimal(db);
    repo = DriftTransactionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('returns domain Transactions with hydrated currency', () async {
    await _insertTx(db: db, id: 1, date: DateTime.utc(2026, 5, 1), memo: 'latte');

    final txs = await repo.watchByMemo('latte').first;

    expect(txs, hasLength(1));
    expect(txs.first.id, 1);
    expect(txs.first.currency.code, 'USD');
    expect(txs.first.currency.decimals, 2);
  });

  test('empty query emits []', () async {
    await _insertTx(db: db, id: 1, date: DateTime.utc(2026, 5, 1), memo: 'latte');

    expect(await repo.watchByMemo('').first, isEmpty);
  });
});
```

- [x] **Step 2: Run, expect failure (method not defined on repository)**

Run: `flutter test test/unit/repositories/transaction_repository_search_test.dart`
Expected: FAIL — `The method 'watchByMemo' isn't defined for ...TransactionRepository`.

- [x] **Step 3: Declare the abstract method**

In `lib/data/repositories/transaction_repository.dart`, inside the `abstract class TransactionRepository` block (near other `watch*` declarations, e.g. after `watchForCategory`):

```dart
/// Transactions whose memo contains [query] (case-insensitive
/// substring). Returns domain models ordered `date DESC, id DESC`.
/// Empty/whitespace queries emit `[]` (DAO short-circuits).
Stream<List<Transaction>> watchByMemo(String query);
```

- [x] **Step 4: Implement on `DriftTransactionRepository`**

Inside `final class DriftTransactionRepository`, near `watchForCategory`:

```dart
@override
Stream<List<Transaction>> watchByMemo(String query) {
  return _dao.watchByMemo(query).asyncMap(_rowsToDomain);
}
```

- [x] **Step 5: Run all search-test cases**

Run: `flutter test test/unit/repositories/transaction_repository_search_test.dart`
Expected: PASS (5 tests).

- [x] **Step 6: Run the full repo test suite to confirm no regression**

Run: `flutter test test/unit/repositories/`
Expected: all PASS.

- [x] **Step 7: Commit**

```bash
dart format lib/data/repositories/transaction_repository.dart \
           test/unit/repositories/transaction_repository_search_test.dart
git add lib/data/repositories/transaction_repository.dart \
        test/unit/repositories/transaction_repository_search_test.dart
git commit -m "feat(data): add TransactionRepository.watchByMemo"
```

---

## Task 4: `AnalysisState` Freezed sealed union

**Files:**
- Create: `lib/features/analysis/analysis_state.dart`

Defines `AnalysisState` (idle / loading / results / empty) and the `CategorySearchResult` value class.

- [x] **Step 1: Write the file**

Create `lib/features/analysis/analysis_state.dart`:

```dart
// Analysis-search state — see
// `docs/superpowers/specs/2026-05-09-transaction-search-design.md`
// § State & Controller.
//
// `AnalysisLoading.previous` carries the prior `AnalysisResults` payload
// so the UI can keep rendering the previous list under a spinner overlay
// while a new query debounces; `null` on the first search.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/category.dart';
import '../../data/models/currency.dart';

part 'analysis_state.freezed.dart';

@freezed
sealed class AnalysisState with _$AnalysisState {
  /// No query typed yet — renders the search-prompt placeholder.
  const factory AnalysisState.idle() = AnalysisIdle;

  /// Query is debouncing or the underlying stream is re-subscribing.
  const factory AnalysisState.loading({
    required String query,
    List<CategorySearchResult>? previous,
  }) = AnalysisLoading;

  /// Query has matching transactions. Categories sorted by most-recent
  /// matching transaction date (descending), tiebreak `categoryId` asc.
  const factory AnalysisState.results({
    required List<CategorySearchResult> categories,
    required String query,
  }) = AnalysisResults;

  /// Query typed but no matching transactions.
  const factory AnalysisState.empty({required String query}) = AnalysisEmpty;
}

@freezed
abstract class CategorySearchResult with _$CategorySearchResult {
  const factory CategorySearchResult({
    /// Full category value object — widget resolves display via
    /// `categoryDisplayName(category, l10n)` (matches `TransactionTile`).
    /// Carries `customName`, `l10nKey`, `icon` (registry key), `color`
    /// (palette index), and `type` (expense/income) without exploding
    /// them into 4-5 scalar copies that diverge over time.
    required Category category,
    required int transactionCount,
    required int totalAmountMinorUnits,
    required Currency currency,
    /// `max(transaction.date)` within this `(category, currency)` group;
    /// primary sort key in `AnalysisResults`.
    required DateTime mostRecentDate,
  }) = _CategorySearchResult;
}
```

- [x] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generates `lib/features/analysis/analysis_state.freezed.dart`.

- [x] **Step 3: Verify it analyzes**

Run: `flutter analyze lib/features/analysis/analysis_state.dart`
Expected: No issues found.

- [x] **Step 4: Commit**

```bash
dart format lib/features/analysis/analysis_state.dart
git add lib/features/analysis/analysis_state.dart \
        lib/features/analysis/analysis_state.freezed.dart
git commit -m "feat(analysis): add AnalysisState and CategorySearchResult"
```

---

## Task 5: `CategorySearchDetailState` Freezed sealed union

**Files:**
- Create: `lib/features/analysis/category_search_detail_state.dart`

- [x] **Step 1: Write the file**

Create `lib/features/analysis/category_search_detail_state.dart`:

```dart
// Detail-screen state for category-filtered search results — see spec
// § UI — Category Search Detail Screen.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/currency.dart';
import '../../data/models/transaction.dart';

part 'category_search_detail_state.freezed.dart';

@freezed
sealed class CategorySearchDetailState with _$CategorySearchDetailState {
  const factory CategorySearchDetailState.loading() = DetailLoading;

  /// `query` and `categoryId` are NOT echoed here — they're already
  /// available as family-key parameters on the controller and as
  /// constructor args on `CategorySearchDetailScreen`. Re-storing them
  /// in state would add fields no consumer reads.
  const factory CategorySearchDetailState.data({
    required List<DatedTransactionGroup> days,
    required int overallSumMinorUnits,
    required Currency currency,
  }) = DetailData;

  const factory CategorySearchDetailState.empty() = DetailEmpty;
}

@freezed
abstract class DatedTransactionGroup with _$DatedTransactionGroup {
  const factory DatedTransactionGroup({
    required DateTime date,
    required List<Transaction> transactions,
    required int daySumMinorUnits,
  }) = _DatedTransactionGroup;
}
```

- [x] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generates `category_search_detail_state.freezed.dart`.

- [x] **Step 3: Analyze**

Run: `flutter analyze lib/features/analysis/category_search_detail_state.dart`
Expected: clean.

- [x] **Step 4: Commit**

```bash
dart format lib/features/analysis/category_search_detail_state.dart
git add lib/features/analysis/category_search_detail_state.dart \
        lib/features/analysis/category_search_detail_state.freezed.dart
git commit -m "feat(analysis): add CategorySearchDetailState"
```

---

## Task 6: Slice-local providers (`analysis_providers.dart`)

**Files:**
- Create: `lib/features/analysis/analysis_providers.dart`

Mirrors `home_providers.dart` exactly. Plain `StreamProvider.autoDispose` (not `@Riverpod`-annotated) so it follows the slice convention; the `keepAlive: true` controllers we build next will hold these alive through the Analysis tab's lifetime.

> **Why duplicate `homeAccountsByIdProvider` instead of importing it?** The duplication is intentional, but the rationale is honest: today no `import_lint` rule blocks `lib/features/analysis/*_providers.dart` from importing `lib/features/home/*_providers.dart`, so this is a *convention*, not an enforced boundary. Two reasons we still keep them separate: (a) the Analysis slice should not implicitly depend on the Home slice's lifecycle — if Home renames or restructures `homeAccountsByIdProvider`, Analysis breaks for no architectural reason; (b) both slices ultimately call the same `accountRepository.watchAll(...)`, so Drift de-duplicates the underlying SQL query — there's no double-subscription cost. If we ever introduce a third caller, promote both lookup providers to a shared location (e.g. `app/providers/lookup_providers.dart`) rather than triplicate.

- [x] **Step 1: Write the file**

Create `lib/features/analysis/analysis_providers.dart`:

```dart
// Analysis slice — co-located Riverpod providers.
//
// Lookups are sourced from `watchAll(includeArchived: true)` so search
// results referencing archived categories / accounts still resolve to
// their metadata. Mirrors `home_providers.dart` style — plain
// `StreamProvider.autoDispose`, not `@Riverpod`-annotated.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';
import '../../data/models/category.dart';

/// `id → Category` lookup (active + archived) for search-result tiles.
final analysisCategoriesByIdProvider =
    StreamProvider.autoDispose<Map<int, Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo
      .watchAll(includeArchived: true)
      .map((rows) => {for (final c in rows) c.id: c});
});

/// `id → Account` lookup (active + archived) for the detail screen's
/// transaction rows.
final analysisAccountsByIdProvider =
    StreamProvider.autoDispose<Map<int, Account>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo
      .watchAll(includeArchived: true)
      .map((rows) => {for (final a in rows) a.id: a});
});
```

- [x] **Step 2: Analyze**

Run: `flutter analyze lib/features/analysis/analysis_providers.dart`
Expected: clean.

- [x] **Step 3: Commit**

```bash
dart format lib/features/analysis/analysis_providers.dart
git add lib/features/analysis/analysis_providers.dart
git commit -m "feat(analysis): add slice-local category/account lookup providers"
```

---

## Task 7: `AnalysisController`

**Files:**
- Create: `lib/features/analysis/analysis_controller.dart`
- Test: `test/unit/controllers/analysis_controller_test.dart` (new)

Riverpod `StreamNotifier<AnalysisState>` with `keepAlive: true`. Lifecycle resources cancelled on every `updateQuery` (and in `ref.onDispose`):
- `_debounceTimer` — 300ms pacing
- `_subscription` — prior `watchByMemo` listener
- `_lastTransactions` — cached for category-only re-grouping
- `_generation` — bumped on every `updateQuery`; async callbacks compare against the captured-at-dispatch value before mutating state

The controller composes two streams:
1. `transactionRepository.watchByMemo(query)` — triggered after debounce; emissions also forward errors via `onError`.
2. `analysisCategoriesByIdProvider` — re-runs `_group` against `_lastTransactions` whenever the category map changes (rename / archive / icon-color edit). This delivers the spec's "live category-update without a new transaction emission" guarantee.

`build()` closes any prior `_emitter` first — `keepAlive: true` does not prevent rebuild on `ref.invalidate` / dependency churn / hot-reload, and `ref.onDispose` only fires on full teardown.

**Test the controller end-to-end with a mocked repository.** Use `fake_async` to drive the 300ms debounce deterministically (see `home_controller_test.dart` for the established pattern).

- [x] **Step 1: Write the controller skeleton**

Create `lib/features/analysis/analysis_controller.dart`:

```dart
// Analysis-search controller — see spec § State & Controller.
//
// Composes `transactionRepository.watchByMemo(query)` with
// `analysisCategoriesByIdProvider` to build per-(category, currency)
// result groups. Cleanup axes:
//   - `_debounceTimer` — 300ms search-as-you-type pacing.
//   - `_subscription`  — cancelled on every `updateQuery`; a slow
//     'co' stream cannot leak emissions onto a faster 'coffee' result.
//   - `_generation`    — counter bumped on every updateQuery; async
//     callbacks compare against captured-at-dispatch value (stronger
//     than a query-string compare).
//   - `_lastTransactions` — cached so a category-map emission can
//     re-group without waiting for a new transactions emission.
//
// `keepAlive: true` so navigation to the detail screen and back
// preserves the typed query and result list. `build()` may still re-run
// (ref.invalidate / dependency churn / hot-reload), so the prior
// `_emitter` is closed at the top of build before a new one is opened.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/category.dart';
import '../../data/models/currency.dart';
import '../../data/models/transaction.dart';
import 'analysis_providers.dart';
import 'analysis_state.dart';

part 'analysis_controller.g.dart';

const Duration _kDebounce = Duration(milliseconds: 300);

@Riverpod(keepAlive: true, dependencies: [transactionRepository])
class AnalysisController extends _$AnalysisController {
  Timer? _debounceTimer;
  StreamSubscription<List<Transaction>>? _subscription;
  String _activeQuery = '';
  int _generation = 0; // bumps on every updateQuery; subscription callbacks
                       // verify the generation hasn't moved on since they fired.
  List<CategorySearchResult>? _lastResults;
  List<Transaction>? _lastTransactions; // cached so a category-map emission
                                        // can re-run `_group` without waiting
                                        // for a new transactions emission
                                        // (spec § 'category live-update').

  @override
  Stream<AnalysisState> build() {
    // Close any prior emitter from a previous `build()` run — `keepAlive: true`
    // does not prevent rebuilds (e.g. on `ref.invalidate`, dependency churn,
    // or hot-reload), and Riverpod calls `ref.onDispose` only on full
    // teardown, not on rebuild. Without this, the prior emitter and its
    // active `_subscription` would leak.
    _emitter?.close();

    final controller = StreamController<AnalysisState>();
    controller.add(const AnalysisState.idle());

    // Re-group on category-map emissions (rename / archive / icon-color
    // change) without requiring a new transactions emission. We re-use the
    // cached `_lastTransactions`; if no query is active or no results have
    // landed yet, this is a no-op.
    ref.listen<AsyncValue<Map<int, Category>>>(
      analysisCategoriesByIdProvider,
      (_, next) {
        final txs = _lastTransactions;
        final cats = next.valueOrNull;
        if (txs == null || cats == null || _activeQuery.isEmpty) return;
        final results = _group(txs, cats);
        if (results.isEmpty) {
          _lastResults = null;
          _emitter?.add(AnalysisState.empty(query: _activeQuery));
        } else {
          _lastResults = results;
          _emitter?.add(AnalysisState.results(
            categories: results,
            query: _activeQuery,
          ));
        }
      },
    );

    ref.onDispose(() {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      _subscription?.cancel();
      _subscription = null;
      controller.close();
    });

    _emitter = controller;
    return controller.stream;
  }

  StreamController<AnalysisState>? _emitter;

  /// Called by the SearchBar `onChanged`.
  void updateQuery(String query) {
    final trimmed = query.trim();
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _lastTransactions = null; // discard cached txs from the prior query
    final myGen = ++_generation; // every call bumps; callbacks compare against this

    if (trimmed.isEmpty) {
      _activeQuery = '';
      _lastResults = null; // clear so a later retype doesn't render stale 'previous'
      _emitter?.add(const AnalysisState.idle());
      return;
    }

    _activeQuery = trimmed;
    _emitter?.add(AnalysisState.loading(query: trimmed, previous: _lastResults));

    _debounceTimer = Timer(_kDebounce, () => _subscribe(trimmed, myGen));
  }

  void _subscribe(String query, int gen) {
    if (gen != _generation) return; // a newer updateQuery already superseded us
    final repo = ref.read(transactionRepositoryProvider);
    _subscription = repo.watchByMemo(query).listen(
      (txs) {
        // Per-subscription stale-emission guard. The generation counter is
        // strictly stronger than `_activeQuery == query`: it distinguishes
        // 'same query, different subscription' (clear → retype same query
        // within the debounce window) which the string compare cannot.
        if (gen != _generation) return;
        _lastTransactions = txs; // remembered so category-map emissions can re-group
        final categoriesById = ref.read(analysisCategoriesByIdProvider).valueOrNull
            ?? const <int, Category>{};
        final results = _group(txs, categoriesById);
        if (results.isEmpty) {
          _lastResults = null;
          _emitter?.add(AnalysisState.empty(query: query));
        } else {
          _lastResults = results;
          _emitter?.add(AnalysisState.results(categories: results, query: query));
        }
      },
      onError: (Object e, StackTrace st) {
        // Forward Drift errors to listeners — without this, `state.when(error: ...)`
        // in `AnalysisScreen` is dead code (the controller never errored its own
        // stream because the upstream error was silently dropped at `.listen`).
        if (gen != _generation) return;
        _emitter?.addError(e, st);
      },
    );
  }

  List<CategorySearchResult> _group(
    List<Transaction> txs,
    Map<int, Category> categoriesById,
  ) {
    // Bucket by (categoryId, currencyCode).
    final buckets = <(int, String), _Bucket>{};
    for (final tx in txs) {
      final key = (tx.categoryId, tx.currency.code);
      final bucket = buckets.putIfAbsent(
        key,
        () => _Bucket(currency: tx.currency, mostRecentDate: tx.date),
      );
      bucket.count++;
      bucket.totalMinor += tx.amountMinorUnits;
      if (tx.date.isAfter(bucket.mostRecentDate)) {
        bucket.mostRecentDate = tx.date;
      }
    }

    final results = <CategorySearchResult>[];
    buckets.forEach((key, bucket) {
      final cat = categoriesById[key.$1];
      if (cat == null) return; // category not (yet) loaded; skip silently
      results.add(CategorySearchResult(
        category: cat,
        transactionCount: bucket.count,
        totalAmountMinorUnits: bucket.totalMinor,
        currency: bucket.currency,
        mostRecentDate: bucket.mostRecentDate,
      ));
    });

    results.sort((a, b) {
      final byDate = b.mostRecentDate.compareTo(a.mostRecentDate);
      if (byDate != 0) return byDate;
      return a.category.id.compareTo(b.category.id);
    });
    return results;
  }
}

class _Bucket {
  _Bucket({required this.currency, required this.mostRecentDate});

  final Currency currency;
  DateTime mostRecentDate;
  int count = 0;
  int totalMinor = 0;
}
```

> **Note on display name:** `CategorySearchResult` carries the full `Category` so the widget can call `categoryDisplayName(category, l10n)` exactly like Home's `TransactionTile`. The controller can't resolve l10n itself (no `BuildContext`), and storing `customName ?? l10nKey` as a raw string would surface keys like `cat.food` for unrenamed seeded categories.

- [x] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generates `analysis_controller.g.dart`.

- [x] **Step 3: Write the controller test scaffolding**

Create `test/unit/controllers/analysis_controller_test.dart`:

```dart
// AnalysisController unit tests — debounce, cancellation, grouping,
// sort key. Repositories mocked via `mocktail`; categories via a
// `StreamController` overridden onto `analysisCategoriesByIdProvider`.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/analysis_controller.dart';
import 'package:ledgerly/features/analysis/analysis_providers.dart';
import 'package:ledgerly/features/analysis/analysis_state.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);

const _jpy = Currency(
  code: 'JPY',
  decimals: 0,
  symbol: '¥',
  nameL10nKey: 'currency.jpy',
);

Category _cat({required int id, String name = 'Coffee'}) => Category(
  id: id,
  type: CategoryType.expense,
  l10nKey: 'cat.coffee',
  customName: name,
  icon: 'coffee',
  color: 1,
  sortOrder: id,
  isArchived: false,
);

Transaction _tx({
  required int id,
  required DateTime date,
  required int categoryId,
  Currency currency = _usd,
  int amount = 1000,
  String? memo = 'coffee',
}) => Transaction(
  id: id,
  amountMinorUnits: amount,
  currency: currency,
  categoryId: categoryId,
  accountId: 1,
  date: date,
  memo: memo,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

ProviderContainer _makeContainer({
  required TransactionRepository repo,
  required Stream<Map<int, Category>> categoriesStream,
}) {
  return ProviderContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repo),
      analysisCategoriesByIdProvider.overrideWith(
        (ref) => categoriesStream,
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  group('AnalysisController', () {
    late _MockTransactionRepository repo;
    late StreamController<List<Transaction>> txCtrl;

    setUp(() {
      repo = _MockTransactionRepository();
      txCtrl = StreamController<List<Transaction>>.broadcast();
      when(() => repo.watchByMemo(any())).thenAnswer((_) => txCtrl.stream);
    });

    tearDown(() async {
      await txCtrl.close();
    });

    test('starts in AnalysisIdle and stays there for empty query', () async {
      final container = _makeContainer(
        repo: repo,
        categoriesStream: Stream.value(const <int, Category>{}),
      );
      addTearDown(container.dispose);

      final state = await container.read(analysisControllerProvider.future);
      expect(state, isA<AnalysisIdle>());

      container.read(analysisControllerProvider.notifier).updateQuery('   ');
      final next = await container.read(analysisControllerProvider.future);
      expect(next, isA<AnalysisIdle>());

      verifyNever(() => repo.watchByMemo(any()));
    });
  });
}
```

- [x] **Step 4: Run, expect pass**

Run: `flutter test test/unit/controllers/analysis_controller_test.dart`
Expected: PASS (1 test). The controller's idle/empty path doesn't subscribe.

- [x] **Step 5: Add the debounce + grouping test**

Append inside `group('AnalysisController', ...)`:

```dart
test('debounces to 300ms then groups by (category, currency)', () {
  fakeAsync((async) {
    final container = _makeContainer(
      repo: repo,
      categoriesStream: Stream.value({1: _cat(id: 1)}),
    );
    addTearDown(container.dispose);
    container.listen(analysisControllerProvider, (_, _) {});

    container.read(analysisControllerProvider.notifier).updateQuery('co');
    container.read(analysisControllerProvider.notifier).updateQuery('cof');
    container.read(analysisControllerProvider.notifier).updateQuery('coffee');
    async.elapse(const Duration(milliseconds: 250));
    verifyNever(() => repo.watchByMemo(any()));

    async.elapse(const Duration(milliseconds: 100)); // total 350 ms after last call
    verify(() => repo.watchByMemo('coffee')).called(1);

    txCtrl.add([
      _tx(id: 1, date: DateTime.utc(2026, 5, 1), categoryId: 1),
      _tx(id: 2, date: DateTime.utc(2026, 5, 3), categoryId: 1),
    ]);
    async.flushMicrotasks();

    final state = container.read(analysisControllerProvider).valueOrNull;
    expect(state, isA<AnalysisResults>());
    final results = (state as AnalysisResults).categories;
    expect(results, hasLength(1));
    expect(results.first.category.id, 1);
    expect(results.first.transactionCount, 2);
    expect(results.first.mostRecentDate, DateTime.utc(2026, 5, 3));
  });
});
```

- [x] **Step 6: Run; verify the test fails meaningfully if any step is wrong, otherwise passes**

Run: `flutter test test/unit/controllers/analysis_controller_test.dart`
Expected: PASS.

If FAIL: read the failure carefully. Common issue is `verifyNever` triggering early because the timer wasn't actually deferred — re-check the controller's `updateQuery` cancels the old timer.

- [x] **Step 7: Add the sort-key test (date desc, categoryId asc tiebreak)**

Append:

```dart
test('sorts by mostRecentDate desc; tiebreak by categoryId asc', () {
  fakeAsync((async) {
    final container = _makeContainer(
      repo: repo,
      categoriesStream: Stream.value({
        1: _cat(id: 1, name: 'Cat-1'),
        2: _cat(id: 2, name: 'Cat-2'),
        3: _cat(id: 3, name: 'Cat-3'),
      }),
    );
    addTearDown(container.dispose);
    container.listen(analysisControllerProvider, (_, _) {});

    container.read(analysisControllerProvider.notifier).updateQuery('coffee');
    async.elapse(const Duration(milliseconds: 350));

    txCtrl.add([
      // Cat 3 — newest
      _tx(id: 10, date: DateTime.utc(2026, 5, 5), categoryId: 3),
      // Cat 1 and Cat 2 — same date; expect cat 1 first by id-asc tiebreak
      _tx(id: 11, date: DateTime.utc(2026, 5, 1), categoryId: 1),
      _tx(id: 12, date: DateTime.utc(2026, 5, 1), categoryId: 2),
    ]);
    async.flushMicrotasks();

    final results =
        (container.read(analysisControllerProvider).valueOrNull
                as AnalysisResults)
            .categories;

    expect(results.map((r) => r.category.id).toList(), [3, 1, 2]);
  });
});
```

- [x] **Step 8: Run, expect pass**

Run: `flutter test test/unit/controllers/analysis_controller_test.dart`
Expected: PASS.

- [x] **Step 9: Add the subscription-cancellation test**

Append:

```dart
test('cancels prior watchByMemo subscription on new query', () {
  fakeAsync((async) {
    var coCancelled = false;
    final coCtrl = StreamController<List<Transaction>>(
      onCancel: () => coCancelled = true,
    );
    final coffeeCtrl = StreamController<List<Transaction>>.broadcast();

    when(() => repo.watchByMemo('co')).thenAnswer((_) => coCtrl.stream);
    when(() => repo.watchByMemo('coffee'))
        .thenAnswer((_) => coffeeCtrl.stream);

    final container = _makeContainer(
      repo: repo,
      categoriesStream: Stream.value({1: _cat(id: 1)}),
    );
    addTearDown(container.dispose);
    addTearDown(() async {
      await coCtrl.close();
      await coffeeCtrl.close();
    });
    container.listen(analysisControllerProvider, (_, _) {});

    container.read(analysisControllerProvider.notifier).updateQuery('co');
    async.elapse(const Duration(milliseconds: 350));
    verify(() => repo.watchByMemo('co')).called(1);

    container.read(analysisControllerProvider.notifier).updateQuery('coffee');
    async.elapse(const Duration(milliseconds: 350));
    verify(() => repo.watchByMemo('coffee')).called(1);

    expect(coCancelled, isTrue);
  });
});
```

- [x] **Step 10: Run, expect pass**

Run: `flutter test test/unit/controllers/analysis_controller_test.dart`
Expected: PASS.

- [x] **Step 11: Add the loading-carries-previous and empty-result tests**

Append:

```dart
test('loading carries previous results on follow-up query', () {
  fakeAsync((async) {
    final container = _makeContainer(
      repo: repo,
      categoriesStream: Stream.value({1: _cat(id: 1)}),
    );
    addTearDown(container.dispose);
    container.listen(analysisControllerProvider, (_, _) {});

    container.read(analysisControllerProvider.notifier).updateQuery('coffee');
    async.elapse(const Duration(milliseconds: 350));
    txCtrl.add([_tx(id: 1, date: DateTime.utc(2026, 5, 1), categoryId: 1)]);
    async.flushMicrotasks();
    expect(
      container.read(analysisControllerProvider).valueOrNull,
      isA<AnalysisResults>(),
    );

    // Pivot to a new query — assert immediately, *before* the second
    // debounce elapses, so we know `previous` is sourced from `_lastResults`
    // and not from a fresh emission. `verifyNever('xyz')` pins the timing.
    container.read(analysisControllerProvider.notifier).updateQuery('xyz');
    verifyNever(() => repo.watchByMemo('xyz'));
    final loading =
        container.read(analysisControllerProvider).valueOrNull
            as AnalysisLoading;
    expect(loading.query, 'xyz');
    expect(loading.previous, isNotNull);
    expect(loading.previous!.first.category.id, 1);
  });
});

test('clear → retype emits loading with previous=null (lastResults cleared on idle)', () {
  fakeAsync((async) {
    final container = _makeContainer(
      repo: repo,
      categoriesStream: Stream.value({1: _cat(id: 1)}),
    );
    addTearDown(container.dispose);
    container.listen(analysisControllerProvider, (_, _) {});

    container.read(analysisControllerProvider.notifier).updateQuery('coffee');
    async.elapse(const Duration(milliseconds: 350));
    txCtrl.add([_tx(id: 1, date: DateTime.utc(2026, 5, 1), categoryId: 1)]);
    async.flushMicrotasks();

    // User clears.
    container.read(analysisControllerProvider.notifier).updateQuery('');
    expect(
      container.read(analysisControllerProvider).valueOrNull,
      isA<AnalysisIdle>(),
    );

    // User types fresh — should NOT show stale 'coffee' results under spinner.
    container.read(analysisControllerProvider.notifier).updateQuery('latte');
    final loading =
        container.read(analysisControllerProvider).valueOrNull
            as AnalysisLoading;
    expect(loading.previous, isNull);
  });
});

test('category-map emission re-emits results without a new transactions emission', () {
  fakeAsync((async) {
    final cats = StreamController<Map<int, Category>>.broadcast();
    addTearDown(cats.close);
    final container = _makeContainer(
      repo: repo,
      categoriesStream: cats.stream,
    );
    addTearDown(container.dispose);
    container.listen(analysisControllerProvider, (_, _) {});

    cats.add({1: _cat(id: 1, name: 'Coffee')});
    async.flushMicrotasks();

    container.read(analysisControllerProvider.notifier).updateQuery('coffee');
    async.elapse(const Duration(milliseconds: 350));
    txCtrl.add([_tx(id: 1, date: DateTime.utc(2026, 5, 1), categoryId: 1)]);
    async.flushMicrotasks();

    var results =
        (container.read(analysisControllerProvider).valueOrNull
                as AnalysisResults)
            .categories;
    expect(results.first.category.customName, 'Coffee');

    // Rename the category. NO new transactions emission — purely a category
    // emission. Previously, the controller only re-grouped inside the tx
    // listener, so the rename would not propagate. With ref.listen on the
    // category provider it now does.
    cats.add({1: _cat(id: 1, name: 'Espresso')});
    async.flushMicrotasks();

    results =
        (container.read(analysisControllerProvider).valueOrNull
                as AnalysisResults)
            .categories;
    expect(results.first.category.customName, 'Espresso');
  });
});

test('Drift stream errors are forwarded to AsyncValue.error', () {
  fakeAsync((async) {
    final errCtrl = StreamController<List<Transaction>>.broadcast();
    when(() => repo.watchByMemo('boom'))
        .thenAnswer((_) => errCtrl.stream);
    addTearDown(errCtrl.close);

    final container = _makeContainer(
      repo: repo,
      categoriesStream: Stream.value({1: _cat(id: 1)}),
    );
    addTearDown(container.dispose);
    container.listen(analysisControllerProvider, (_, _) {});

    container.read(analysisControllerProvider.notifier).updateQuery('boom');
    async.elapse(const Duration(milliseconds: 350));
    errCtrl.addError(StateError('db locked'));
    async.flushMicrotasks();

    expect(container.read(analysisControllerProvider).hasError, isTrue);
  });
});

test('empty result emits AnalysisEmpty', () {
  fakeAsync((async) {
    final container = _makeContainer(
      repo: repo,
      categoriesStream: Stream.value({1: _cat(id: 1)}),
    );
    addTearDown(container.dispose);
    container.listen(analysisControllerProvider, (_, _) {});

    container.read(analysisControllerProvider.notifier).updateQuery('zzz');
    async.elapse(const Duration(milliseconds: 350));
    txCtrl.add(const []);
    async.flushMicrotasks();

    expect(
      container.read(analysisControllerProvider).valueOrNull,
      isA<AnalysisEmpty>(),
    );
  });
});
```

- [x] **Step 12: Run, expect pass**

Run: `flutter test test/unit/controllers/analysis_controller_test.dart`
Expected: PASS (6 tests total).

- [x] **Step 13: Verify riverpod_lint accepts the dependencies list**

Run: `flutter analyze lib/features/analysis/analysis_controller.dart`
Expected: clean — no `scoped_providers_should_specify_dependencies` warning.

If the lint flags `analysisCategoriesByIdProvider` (a plain `StreamProvider`, not `@Riverpod`-annotated), the codebase convention is that `dependencies:` lists generator-annotated direct watch targets only — see `repository_providers.dart` for precedent. If the warning appears anyway, add an inline `// ignore: scoped_providers_should_specify_dependencies` with a comment pointing at this rationale. Do NOT add the plain provider to the `dependencies:` list — `riverpod_generator` rejects non-annotated entries there.

- [x] **Step 14: Commit**

```bash
dart format lib/features/analysis/analysis_controller.dart \
           test/unit/controllers/analysis_controller_test.dart
git add lib/features/analysis/analysis_controller.dart \
        lib/features/analysis/analysis_controller.g.dart \
        test/unit/controllers/analysis_controller_test.dart
git commit -m "feat(analysis): add AnalysisController with debounce and grouping"
```

---

## Task 8: `CategorySearchDetailController` family

**Files:**
- Create: `lib/features/analysis/category_search_detail_controller.dart`
- Test: `test/unit/controllers/category_search_detail_controller_test.dart` (new)

Family controller keyed on `(int categoryId, String query, String currencyCode)`. Subscribes to `watchByMemo(query)`, filters in-memory by `categoryId` AND `currency.code`, groups by `DateHelpers.startOfDay(transaction.date)`, computes per-day and overall sums.

> **Why filter in Dart, not SQL:** the parent `AnalysisController` already needs every memo-match across categories and currencies (to render Level 1's per-pair cards). Re-using the same `watchByMemo` stream for the detail page avoids a second Drift subscription on the same table when the user drills down. Within MVP's documented 10k-transactions cap, the worst-case in-memory scan is O(N) over the bounded memo-match set — fast and predictable. If profiling at production scale ever shows this is hot, add `watchByMemoInCategory(query, categoryId, currencyCode)` to `TransactionDao` and switch the family to that.

- [x] **Step 1: Write the controller**

Create `lib/features/analysis/category_search_detail_controller.dart`:

```dart
// Detail-screen controller — see spec § Detail Screen State & Controller.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../core/utils/date_helpers.dart';
import '../../data/models/transaction.dart';
import 'category_search_detail_state.dart';

part 'category_search_detail_controller.g.dart';

@Riverpod(dependencies: [transactionRepository])
class CategorySearchDetailController extends _$CategorySearchDetailController {
  @override
  Stream<CategorySearchDetailState> build({
    required int categoryId,
    required String query,
    required String currencyCode,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty || currencyCode.isEmpty) {
      return Stream.value(const CategorySearchDetailState.empty());
    }

    final repo = ref.watch(transactionRepositoryProvider);
    return repo.watchByMemo(trimmed).map((all) {
      final filtered = all
          .where((t) => t.categoryId == categoryId && t.currency.code == currencyCode)
          .toList();
      if (filtered.isEmpty) {
        return const CategorySearchDetailState.empty();
      }

      final byDay = <DateTime, List<Transaction>>{};
      for (final tx in filtered) {
        final day = DateHelpers.startOfDay(tx.date);
        byDay.putIfAbsent(day, () => <Transaction>[]).add(tx);
      }

      final days = byDay.entries
          .map(
            (e) => DatedTransactionGroup(
              date: e.key,
              transactions: e.value,
              daySumMinorUnits: e.value.fold<int>(
                0,
                (sum, t) => sum + t.amountMinorUnits,
              ),
            ),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final overall = days.fold<int>(
        0,
        (sum, day) => sum + day.daySumMinorUnits,
      );
      return CategorySearchDetailState.data(
        days: days,
        overallSumMinorUnits: overall,
        currency: filtered.first.currency,
      );
    });
  }
}
```

- [x] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generates `category_search_detail_controller.g.dart`.

- [x] **Step 3: Write the test file**

Create `test/unit/controllers/category_search_detail_controller_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/category_search_detail_controller.dart';
import 'package:ledgerly/features/analysis/category_search_detail_state.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);
const _jpy = Currency(
  code: 'JPY',
  decimals: 0,
  symbol: '¥',
  nameL10nKey: 'currency.jpy',
);

Transaction _tx({
  required int id,
  required DateTime date,
  required int categoryId,
  Currency currency = _usd,
  int amount = 1000,
}) => Transaction(
  id: id,
  amountMinorUnits: amount,
  currency: currency,
  categoryId: categoryId,
  accountId: 1,
  date: date,
  memo: 'coffee',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  group('CategorySearchDetailController', () {
    late _MockTransactionRepository repo;

    setUp(() {
      repo = _MockTransactionRepository();
    });

    test('empty query emits DetailEmpty without subscribing', () async {
      when(() => repo.watchByMemo(any())).thenAnswer((_) => const Stream.empty());

      final container = ProviderContainer(
        overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        categorySearchDetailControllerProvider(
          categoryId: 1,
          query: '   ',
          currencyCode: 'USD',
        ).future,
      );
      expect(state, isA<DetailEmpty>());
      verifyNever(() => repo.watchByMemo(any()));
    });

    test('filters by categoryId AND currency.code', () async {
      when(() => repo.watchByMemo('coffee')).thenAnswer(
        (_) => Stream.value([
          _tx(id: 1, date: DateTime.utc(2026, 5, 1), categoryId: 1, currency: _usd),
          _tx(id: 2, date: DateTime.utc(2026, 5, 1), categoryId: 1, currency: _jpy),
          _tx(id: 3, date: DateTime.utc(2026, 5, 1), categoryId: 2, currency: _usd),
        ]),
      );

      final container = ProviderContainer(
        overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        categorySearchDetailControllerProvider(
          categoryId: 1,
          query: 'coffee',
          currencyCode: 'USD',
        ).future,
      );
      final data = state as DetailData;
      expect(data.days, hasLength(1));
      expect(data.days.first.transactions.map((t) => t.id), [1]);
      expect(data.currency.code, 'USD');
    });

    test('groups by local-midnight day and sums', () async {
      when(() => repo.watchByMemo('coffee')).thenAnswer(
        (_) => Stream.value([
          _tx(id: 1, date: DateTime.utc(2026, 5, 1, 23, 59), categoryId: 1, amount: 100),
          _tx(id: 2, date: DateTime.utc(2026, 5, 2, 0, 1),  categoryId: 1, amount: 200),
          _tx(id: 3, date: DateTime.utc(2026, 5, 2, 12, 0), categoryId: 1, amount: 300),
        ]),
      );

      final container = ProviderContainer(
        overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        categorySearchDetailControllerProvider(
          categoryId: 1,
          query: 'coffee',
          currencyCode: 'USD',
        ).future,
      );
      final data = state as DetailData;
      // Two days; the May-2 group has the larger sum (200 + 300 = 500),
      // and is sorted first (date desc).
      expect(data.days.map((d) => d.daySumMinorUnits).toList(), [500, 100]);
      expect(data.overallSumMinorUnits, 600);
    });
  });
}
```

- [x] **Step 4: Run all detail-controller tests**

Run: `flutter test test/unit/controllers/category_search_detail_controller_test.dart`
Expected: PASS (3 tests).

- [x] **Step 5: Commit**

```bash
dart format lib/features/analysis/category_search_detail_controller.dart \
           test/unit/controllers/category_search_detail_controller_test.dart
git add lib/features/analysis/category_search_detail_controller.dart \
        lib/features/analysis/category_search_detail_controller.g.dart \
        test/unit/controllers/category_search_detail_controller_test.dart
git commit -m "feat(analysis): add CategorySearchDetailController family"
```

---

## Task 9: `TransactionSearchRow` widget (read-only)

**Files:**
- Create: `lib/features/analysis/widgets/transaction_search_row.dart`

Read-only row — `ListTile` only. No `Slidable`, no `PopupMenuButton`, no `onTap`. Visual layout matches `TransactionTile` (icon, title, "account • memo" subtitle, signed amount with type-driven color).

- [x] **Step 1: Write the widget**

Create `lib/features/analysis/widgets/transaction_search_row.dart`:

```dart
// Read-only transaction row for search results — see spec
// § Transaction tiles.
//
// Search results are a *view* over transactions, not an action surface.
// Mutations from a filtered view would silently change the result set
// under the user, so this widget is intentionally presentational only —
// no tap, no swipe, no overflow menu. Editing/duplicating/deleting
// belongs to Home and the dedicated edit form.

import 'package:flutter/material.dart';

import '../../../core/utils/color_palette.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/widgets/category_display.dart';

class TransactionSearchRow extends StatelessWidget {
  const TransactionSearchRow({
    super.key,
    required this.transaction,
    required this.category,
    required this.account,
    required this.locale,
  });

  final Transaction transaction;
  final Category? category;
  final Account? account;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cat = category;
    final acc = account;

    final color = cat != null ? colorForIndex(cat.color) : theme.disabledColor;
    final icon = cat != null ? iconForKey(cat.icon) : Icons.help_outline;
    final isIncome = cat?.type == CategoryType.income;

    final amountText = switch (cat?.type) {
      CategoryType.income => MoneyFormatter.formatSigned(
        amountMinorUnits: transaction.amountMinorUnits,
        currency: transaction.currency,
        locale: locale,
      ),
      CategoryType.expense => MoneyFormatter.formatSigned(
        amountMinorUnits: -transaction.amountMinorUnits,
        currency: transaction.currency,
        locale: locale,
      ),
      null => MoneyFormatter.format(
        amountMinorUnits: transaction.amountMinorUnits,
        currency: transaction.currency,
        locale: locale,
      ),
    };

    final memo = transaction.memo;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(
        cat == null ? '' : categoryDisplayName(cat, l10n),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        memo == null || memo.isEmpty
            ? (acc?.name ?? '')
            : '${acc?.name ?? ''} • $memo',
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        amountText,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isIncome ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Analyze**

Run: `flutter analyze lib/features/analysis/widgets/transaction_search_row.dart`
Expected: clean.

- [x] **Step 3: Commit**

```bash
dart format lib/features/analysis/widgets/transaction_search_row.dart
git add lib/features/analysis/widgets/transaction_search_row.dart
git commit -m "feat(analysis): add read-only TransactionSearchRow widget"
```

---

## Task 10: `CategorySearchTile` widget

**Files:**
- Create: `lib/features/analysis/widgets/category_search_tile.dart`

Level 1 result card. Tap → `context.push('/analysis/search/:categoryId?q=…&c=…')`.

- [x] **Step 1: Write the widget**

Create `lib/features/analysis/widgets/category_search_tile.dart`:

```dart
// Level 1 result card — see spec § CategorySearchTile widget.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/color_palette.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../data/models/category.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/widgets/category_display.dart';
import '../analysis_state.dart';

class CategorySearchTile extends StatelessWidget {
  const CategorySearchTile({
    super.key,
    required this.result,
    required this.query,
    required this.locale,
  });

  final CategorySearchResult result;
  final String query;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cat = result.category;
    final color = colorForIndex(cat.color);
    final icon = iconForKey(cat.icon);
    final isIncome = cat.type == CategoryType.income;
    final signedAmount = isIncome
        ? result.totalAmountMinorUnits
        : -result.totalAmountMinorUnits;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(
        categoryDisplayName(cat, l10n),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(l10n.analysisTransactionCount(result.transactionCount)),
      trailing: Text(
        MoneyFormatter.formatSigned(
          amountMinorUnits: signedAmount,
          currency: result.currency,
          locale: locale,
        ),
        style: theme.textTheme.titleMedium?.copyWith(
          color: isIncome ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => context.push(
        Uri(
          path: '/analysis/search/${cat.id}',
          queryParameters: {'q': query, 'c': result.currency.code},
        ).toString(),
      ),
    );
  }
}
```

The full `Category` arrives on `result.category`, so display name uses the project-wide `categoryDisplayName(cat, l10n)` helper — same call site `TransactionTile` and every other category-rendering screen makes. No raw `cat.food` keys ever surface to users.

- [x] **Step 2: Analyze**

Run: `flutter analyze lib/features/analysis/widgets/category_search_tile.dart`
Expected: clean.

- [x] **Step 3: Commit**

```bash
dart format lib/features/analysis/widgets/category_search_tile.dart
git add lib/features/analysis/widgets/category_search_tile.dart
git commit -m "feat(analysis): add CategorySearchTile widget"
```

---

## Task 11: `AnalysisSearchPlaceholder` widget

**Files:**
- Create: `lib/features/analysis/widgets/analysis_search_placeholder.dart`

Idle-state copy: search icon + `analysisSearchPrompt`. Replaces the Phase 2 placeholder body.

- [x] **Step 1: Write the widget**

Create `lib/features/analysis/widgets/analysis_search_placeholder.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class AnalysisSearchPlaceholder extends StatelessWidget {
  const AnalysisSearchPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.analysisSearchPrompt,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Analyze**

Run: `flutter analyze lib/features/analysis/widgets/analysis_search_placeholder.dart`
Expected: clean.

- [x] **Step 3: Commit**

```bash
dart format lib/features/analysis/widgets/analysis_search_placeholder.dart
git add lib/features/analysis/widgets/analysis_search_placeholder.dart
git commit -m "feat(analysis): add AnalysisSearchPlaceholder idle widget"
```

---

## Task 12: Rewrite `AnalysisScreen`

**Files:**
- Modify: `lib/features/analysis/analysis_screen.dart`
- Test: `test/widget/features/analysis/analysis_screen_test.dart` (new)

Material 3 inline `SearchBar` in `AppBar.bottom` + state-driven body.

- [x] **Step 1: Replace the screen body**

Open `lib/features/analysis/analysis_screen.dart`. Replace the entire file contents:

```dart
// Analysis tab — memo-based transaction search.
// See `docs/superpowers/specs/2026-05-09-transaction-search-design.md`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'analysis_controller.dart';
import 'analysis_state.dart';
import 'widgets/analysis_search_placeholder.dart';
import 'widgets/category_search_tile.dart';

/// Material 3 SearchBar default height (56dp).
const double _kSearchBarBaseHeight = 56;
const double _kSearchBarVerticalPadding = 8;

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onClear() {
    _searchController.clear();
    _searchFocus.unfocus(); // dismiss the soft keyboard so the placeholder isn't covered
    ref.read(analysisControllerProvider.notifier).updateQuery('');
    setState(() {}); // refresh trailing-button visibility
  }

  void _onChanged(String value) {
    // Skip dispatch while a CJK IME is mid-composition. Pinyin/zhuyin fires
    // `onChanged` for every partial composition keypress; without this guard,
    // each one would cancel the prior subscription and restart the 300ms
    // timer, producing N rapid loading flashes before the user has committed
    // a single character.
    if (_searchController.value.composing.isValid) {
      setState(() {}); // still refresh trailing × visibility
      return;
    }
    ref.read(analysisControllerProvider.notifier).updateQuery(value);
    setState(() {});
  }

  /// Search-bar row height clamped at 1.5× text-scale so accessibility text
  /// sizes don't clip the input. Matches CLAUDE.md "fixed-height widgets
  /// clamp at 1.5× or reflow".
  double _searchBarRowHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final scaled = scaler.clamp(maxScaleFactor: 1.5).scale(_kSearchBarBaseHeight);
    return scaled + _kSearchBarVerticalPadding * 2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final state = ref.watch(analysisControllerProvider);

    final body = state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.analysisErrorMessage)),
      data: (s) => switch (s) {
        AnalysisIdle() => const AnalysisSearchPlaceholder(),
        AnalysisLoading(:final previous, :final query) =>
          previous == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    ListView.builder(
                      itemCount: previous.length,
                      itemBuilder: (_, i) => CategorySearchTile(
                        result: previous[i],
                        query: query,
                        locale: locale,
                      ),
                    ),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ),
        AnalysisResults(:final categories, :final query) => ListView.builder(
          itemCount: categories.length,
          itemBuilder: (_, i) => CategorySearchTile(
            result: categories[i],
            query: query,
            locale: locale,
          ),
        ),
        AnalysisEmpty() => Center(child: Text(l10n.analysisNoResults)),
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analysisTitle),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_searchBarRowHeight(context)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: _kSearchBarVerticalPadding,
            ),
            child: SearchBar(
              controller: _searchController,
              focusNode: _searchFocus,
              hintText: l10n.analysisSearchHint,
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _onClear,
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  ),
              ],
              onChanged: _onChanged,
            ),
          ),
        ),
      ),
      // Wrap the body in a live-region Semantics node so screen readers
      // announce result/empty/error transitions as the search-as-you-type
      // stream emits new state.
      body: Semantics(
        liveRegion: true,
        container: true,
        child: body,
      ),
    );
  }
}
```

- [x] **Step 2: Analyze**

Run: `flutter analyze lib/features/analysis/analysis_screen.dart`
Expected: clean. If `import_lint` complains about a forbidden import, the screen should only import `app/providers/...` and feature-local files — re-check imports.

- [x] **Step 3: Write a basic widget test**

Create `test/widget/features/analysis/analysis_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/analysis_screen.dart';
import 'package:ledgerly/features/analysis/widgets/analysis_search_placeholder.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

Widget _harness({
  required TransactionRepository tx,
  required CategoryRepository cat,
  required AccountRepository acct,
}) {
  return ProviderScope(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(tx),
      categoryRepositoryProvider.overrideWithValue(cat),
      accountRepositoryProvider.overrideWithValue(acct),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AnalysisScreen(),
    ),
  );
}

void main() {
  late _MockTransactionRepository tx;
  late _MockCategoryRepository cat;
  late _MockAccountRepository acct;

  setUp(() {
    tx = _MockTransactionRepository();
    cat = _MockCategoryRepository();
    acct = _MockAccountRepository();
    when(() => cat.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value(const <Category>[]));
    when(() => acct.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value(const <Account>[]));
  });

  testWidgets('renders idle placeholder by default', (tester) async {
    await tester.pumpWidget(_harness(tx: tx, cat: cat, acct: acct));
    await tester.pump(); // settle the controller's first emission

    expect(find.byType(AnalysisSearchPlaceholder), findsOneWidget);
  });

  testWidgets('shows no-results copy when query has no matches',
      (tester) async {
    when(() => tx.watchByMemo(any()))
        .thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(_harness(tx: tx, cat: cat, acct: acct));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('No transactions found'), findsOneWidget);
  });
}
```

- [x] **Step 4: Run, expect pass**

Run: `flutter test test/widget/features/analysis/analysis_screen_test.dart`
Expected: PASS (2 tests).

- [x] **Step 5: Commit**

```bash
dart format lib/features/analysis/analysis_screen.dart \
           test/widget/features/analysis/analysis_screen_test.dart
git add lib/features/analysis/analysis_screen.dart \
        test/widget/features/analysis/analysis_screen_test.dart
git commit -m "feat(analysis): rewrite AnalysisScreen with state-driven SearchBar"
```

---

## Task 13: `CategorySearchDetailScreen`

**Files:**
- Create: `lib/features/analysis/category_search_detail_screen.dart`
- Test: `test/widget/features/analysis/category_search_detail_screen_test.dart` (new)

Header (overall sum) + grouped-by-date `ListView` of `TransactionSearchRow`s with per-day subtotals.

- [x] **Step 1: Write the screen**

Create `lib/features/analysis/category_search_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/money_formatter.dart';
import '../../data/models/category.dart';
import '../../l10n/app_localizations.dart';
import '../categories/widgets/category_display.dart';
import 'analysis_providers.dart';
import 'category_search_detail_controller.dart';
import 'category_search_detail_state.dart';
import 'widgets/transaction_search_row.dart';

class CategorySearchDetailScreen extends ConsumerWidget {
  const CategorySearchDetailScreen({
    super.key,
    required this.categoryId,
    required this.query,
    required this.currencyCode,
  });

  final int categoryId;
  final String query;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);

    final state = ref.watch(
      categorySearchDetailControllerProvider(
        categoryId: categoryId,
        query: query,
        currencyCode: currencyCode,
      ),
    );

    final categoriesAsync = ref.watch(analysisCategoriesByIdProvider);
    final accountsAsync = ref.watch(analysisAccountsByIdProvider);
    final categoriesById =
        categoriesAsync.valueOrNull ?? const <int, Category>{};
    final accountsById = accountsAsync.valueOrNull ?? const {};

    final category = categoriesById[categoryId];
    final appBarTitle = category == null ? '' : categoryDisplayName(category, l10n);

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.analysisErrorMessage)),
        data: (s) => switch (s) {
          DetailLoading() =>
            const Center(child: CircularProgressIndicator()),
          DetailEmpty() => Center(child: Text(l10n.analysisNoResults)),
          DetailData(
            :final days,
            :final overallSumMinorUnits,
            :final currency,
          ) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.analysisSearchTotal,
                        style: theme.textTheme.titleMedium),
                    Text(
                      MoneyFormatter.formatSigned(
                        amountMinorUnits:
                            category?.type == CategoryType.income
                                ? overallSumMinorUnits
                                : -overallSumMinorUnits,
                        currency: currency,
                        locale: locale,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: category?.type == CategoryType.income
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: days.length,
                  itemBuilder: (ctx, dayIdx) {
                    final day = days[dayIdx];
                    final daySigned = category?.type == CategoryType.income
                        ? day.daySumMinorUnits
                        : -day.daySumMinorUnits;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat.yMMMd(locale).format(day.date),
                                style: theme.textTheme.labelMedium,
                              ),
                              Text(
                                MoneyFormatter.formatSigned(
                                  amountMinorUnits: daySigned,
                                  currency: currency,
                                  locale: locale,
                                ),
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        for (final tx in day.transactions)
                          TransactionSearchRow(
                            transaction: tx,
                            category: categoriesById[tx.categoryId],
                            account: accountsById[tx.accountId],
                            locale: locale,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
```

- [x] **Step 2: Analyze**

Run: `flutter analyze lib/features/analysis/category_search_detail_screen.dart`
Expected: clean.

- [x] **Step 3: Write a smoke widget test**

Create `test/widget/features/analysis/category_search_detail_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/analysis_screen.dart';
import 'package:ledgerly/features/analysis/category_search_detail_screen.dart';
import 'package:ledgerly/features/analysis/widgets/category_search_tile.dart';
import 'package:ledgerly/features/analysis/widgets/transaction_search_row.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockAccountRepository extends Mock implements AccountRepository {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);

Category _cat() => Category(
  id: 1,
  type: CategoryType.expense,
  l10nKey: 'cat.coffee',
  customName: 'Coffee',
  icon: 'coffee',
  color: 1,
  sortOrder: 1,
  isArchived: false,
);

Account _acct() => Account(
  id: 1,
  accountTypeId: 1,
  name: 'Cash',
  currency: _usd,
  openingBalanceMinorUnits: 0,
  sortOrder: 1,
  isArchived: false,
);

Transaction _tx() => Transaction(
  id: 1,
  amountMinorUnits: 1000,
  currency: _usd,
  categoryId: 1,
  accountId: 1,
  date: DateTime.utc(2026, 5, 1),
  memo: 'coffee',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  testWidgets('renders read-only TransactionSearchRow', (tester) async {
    final tx = _MockTransactionRepository();
    final cat = _MockCategoryRepository();
    final acct = _MockAccountRepository();

    when(() => tx.watchByMemo('coffee'))
        .thenAnswer((_) => Stream.value([_tx()]));
    when(() => cat.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([_cat()]));
    when(() => acct.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([_acct()]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(tx),
          categoryRepositoryProvider.overrideWithValue(cat),
          accountRepositoryProvider.overrideWithValue(acct),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: CategorySearchDetailScreen(
            categoryId: 1,
            query: 'coffee',
            currencyCode: 'USD',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(TransactionSearchRow), findsOneWidget);
    // Read-only — no Slidable, no PopupMenuButton
    expect(find.byType(PopupMenuButton<dynamic>), findsNothing);
  });

  testWidgets('back navigation preserves AnalysisController query (keepAlive)',
      (tester) async {
    final tx = _MockTransactionRepository();
    final cat = _MockCategoryRepository();
    final acct = _MockAccountRepository();

    when(() => tx.watchByMemo('coffee'))
        .thenAnswer((_) => Stream.value([_tx()]));
    when(() => cat.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([_cat()]));
    when(() => acct.watchAll(includeArchived: true))
        .thenAnswer((_) => Stream.value([_acct()]));

    final router = GoRouter(
      initialLocation: '/analysis',
      routes: [
        GoRoute(
          path: '/analysis',
          builder: (_, _) => const AnalysisScreen(),
          routes: [
            GoRoute(
              path: 'search/:categoryId',
              builder: (_, state) => CategorySearchDetailScreen(
                categoryId: int.parse(state.pathParameters['categoryId']!),
                query: state.uri.queryParameters['q']!,
                currencyCode: state.uri.queryParameters['c']!,
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(tx),
          categoryRepositoryProvider.overrideWithValue(cat),
          accountRepositoryProvider.overrideWithValue(acct),
        ],
        child: MaterialApp.router(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    // Type 'coffee', wait for the debounce, expect the result tile.
    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.byType(CategorySearchTile), findsOneWidget);

    // Drill into detail.
    await tester.tap(find.byType(CategorySearchTile));
    await tester.pumpAndSettle();
    expect(find.byType(CategorySearchDetailScreen), findsOneWidget);

    // Pop back. AnalysisController is keepAlive, so the prior results
    // should re-render without re-debouncing.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(AnalysisScreen), findsOneWidget);
    expect(find.byType(CategorySearchTile), findsOneWidget);
    // The text editor's text persists because _AnalysisScreenState is the
    // same instance (kept in the widget tree by the shell).
    expect(find.widgetWithText(TextField, 'coffee'), findsOneWidget);
  });
}
```

- [x] **Step 4: Run, expect pass**

Run: `flutter test test/widget/features/analysis/category_search_detail_screen_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
dart format lib/features/analysis/category_search_detail_screen.dart \
           test/widget/features/analysis/category_search_detail_screen_test.dart
git add lib/features/analysis/category_search_detail_screen.dart \
        test/widget/features/analysis/category_search_detail_screen_test.dart
git commit -m "feat(analysis): add CategorySearchDetailScreen"
```

---

## Task 14: Wire the route into `router.dart`

**Files:**
- Modify: `lib/app/router.dart`
- Test: `test/widget/features/analysis/analysis_screen_test.dart` (extend with router-guard tests)

Add a child route under `/analysis` with all three guards (`categoryId` int, non-empty `q`, non-empty `c`).

**Shell-branch behavior:** `/analysis` lives inside the bottom-nav `StatefulShellBranch`. The detail screen is a *navigational drill-down within the Analysis tab*, not a modal that should hide the bottom nav — so the new child route stays in-shell (no `parentNavigatorKey: _rootNavigatorKey`). Tapping a result card pushes within the Analysis branch, the bottom nav stays visible, and `context.pop()` returns to the Analysis list. This matches how `/home/edit/:id` would behave if it kept the shell (compare to other routes that explicitly opt into `_rootNavigatorKey` for full-screen modal presentation — those choose to hide the shell on purpose).

- [x] **Step 1: Add the import**

Open `lib/app/router.dart`. Near the existing `import '../features/analysis/analysis_screen.dart';` (line 9), add:

```dart
import '../features/analysis/category_search_detail_screen.dart';
```

- [x] **Step 2: Add the child route**

Find the `/analysis` `GoRoute` (currently:

```dart
GoRoute(
  path: '/analysis',
  builder: (_, _) => const AnalysisScreen(),
),
```

Replace it with:

```dart
GoRoute(
  path: '/analysis',
  builder: (_, _) => const AnalysisScreen(),
  routes: [
    GoRoute(
      path: 'search/:categoryId',
      builder: (context, state) {
        final categoryId =
            int.tryParse(state.pathParameters['categoryId'] ?? '');
        final query = state.uri.queryParameters['q']?.trim() ?? '';
        final currencyCode = state.uri.queryParameters['c'] ?? '';
        if (categoryId == null || query.isEmpty || currencyCode.isEmpty) {
          return const AnalysisScreen();
        }
        return CategorySearchDetailScreen(
          categoryId: categoryId,
          query: query,
          currencyCode: currencyCode,
        );
      },
    ),
  ],
),
```

- [x] **Step 3: Add router-guard widget tests**

Append to `test/widget/features/analysis/analysis_screen_test.dart`:

```dart
import 'package:go_router/go_router.dart';
import 'package:ledgerly/features/analysis/category_search_detail_screen.dart';

GoRouter _guardRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/analysis',
        builder: (_, _) => const AnalysisScreen(),
        routes: [
          GoRoute(
            path: 'search/:categoryId',
            builder: (context, state) {
              final categoryId =
                  int.tryParse(state.pathParameters['categoryId'] ?? '');
              final query = state.uri.queryParameters['q']?.trim() ?? '';
              final currencyCode = state.uri.queryParameters['c'] ?? '';
              if (categoryId == null || query.isEmpty || currencyCode.isEmpty) {
                return const AnalysisScreen();
              }
              return CategorySearchDetailScreen(
                categoryId: categoryId,
                query: query,
                currencyCode: currencyCode,
              );
            },
          ),
        ],
      ),
    ],
  );
}

Widget _routerHarness({
  required TransactionRepository tx,
  required CategoryRepository cat,
  required AccountRepository acct,
  required String initialLocation,
}) {
  return ProviderScope(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(tx),
      categoryRepositoryProvider.overrideWithValue(cat),
      accountRepositoryProvider.overrideWithValue(acct),
    ],
    child: MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _guardRouter(initialLocation),
    ),
  );
}

void _routerGuardTests() {
  group('router guards', () {
    late _MockTransactionRepository tx;
    late _MockCategoryRepository cat;
    late _MockAccountRepository acct;

    setUp(() {
      tx = _MockTransactionRepository();
      cat = _MockCategoryRepository();
      acct = _MockAccountRepository();
      when(() => cat.watchAll(includeArchived: true))
          .thenAnswer((_) => Stream.value(const <Category>[]));
      when(() => acct.watchAll(includeArchived: true))
          .thenAnswer((_) => Stream.value(const <Account>[]));
      when(() => tx.watchByMemo(any()))
          .thenAnswer((_) => const Stream.empty());
    });

    Future<void> _expectFallback(WidgetTester tester, String path) async {
      await tester.pumpWidget(_routerHarness(
        tx: tx, cat: cat, acct: acct, initialLocation: path,
      ));
      await tester.pump();
      expect(find.byType(AnalysisScreen), findsOneWidget);
      expect(find.byType(CategorySearchDetailScreen), findsNothing);
    }

    testWidgets('non-int categoryId falls back to AnalysisScreen',
        (tester) async {
      await _expectFallback(tester, '/analysis/search/abc?q=coffee&c=USD');
    });

    testWidgets('empty q falls back to AnalysisScreen', (tester) async {
      await _expectFallback(tester, '/analysis/search/5?q=&c=USD');
    });

    testWidgets('empty c falls back to AnalysisScreen', (tester) async {
      await _expectFallback(tester, '/analysis/search/5?q=coffee&c=');
    });

    testWidgets('whitespace-only q (after trim) falls back', (tester) async {
      await _expectFallback(tester, '/analysis/search/5?q=%20%20&c=USD');
    });
  });
}
```

Then call `_routerGuardTests();` from `void main()` after the existing tests. The harness duplicates the route table from `router.dart` so the tests don't need the real shell — the guard logic is the same pure function either way.

- [x] **Step 4: Analyze**

Run: `dart format lib/app/router.dart && flutter analyze lib/app/router.dart`
Expected: clean.

- [x] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: all PASS.

- [x] **Step 6: Commit**

```bash
git add lib/app/router.dart \
        test/widget/features/analysis/analysis_screen_test.dart
git commit -m "feat(routing): add /analysis/search/:categoryId child route with guards"
```

---

## Task 15: Manual smoke + final verification

**Files:** none — runtime only.

- [x] **Step 1: Run codegen one final time and analyze**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
```
Expected: no issues.

- [x] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: all PASS.

- [x] **Step 3: Manual smoke on a simulator**

Run: `flutter run` and exercise:

1. Open the Analysis tab → confirm the search-prompt placeholder renders ("Search memos to find past transactions" + magnifying-glass icon).
2. Type a memo substring you know matches → confirm category cards appear within ~300ms; each shows count + signed total.
3. Tap a card → detail page opens with the category name as title, overall sum at top, transactions grouped by date with per-day subtotals.
4. Confirm rows are read-only — try to swipe (no slidable action), try to long-press / tap (no menu, no navigation).
5. Tap back → Analysis tab still shows the previous query and results (`keepAlive` works).
6. Clear the search bar via the trailing × → returns to placeholder, no spinner or stale list.
7. Multi-currency: search a memo that has matches in USD and JPY → confirm two cards (one per `(category, currency)` pair) for each matching category. Tap into each; verify the overall sum stays in that single currency.

- [x] **Step 4: Test broken deep-links manually (router guards)**

In a debug console or via `adb shell am start` / iOS deeplink, test:
- `/analysis/search/abc?q=coffee&c=USD` (non-int id) → falls back to `AnalysisScreen`.
- `/analysis/search/5?q=&c=USD` (empty q) → falls back.
- `/analysis/search/5?q=coffee&c=` (empty currency) → falls back.

(If the project's deep-link harness isn't ready, eyeball the guard logic in `router.dart` line for line — it's a pure function.)

- [x] **Step 5: Commit (only if anything changed during smoke)**

If the smoke surfaced fixes:

```bash
dart format .
git add <changed files>
git commit -m "fix(analysis): <describe the smoke fix>"
```

Otherwise, no-op — the feature is ready for review.

---

## Self-Review Checklist (run before handing the plan over)

- **Spec coverage:**
  - DAO `watchByMemo` (typed Drift builder, empty-query short-circuit) → Task 2 ✅
  - Repository `watchByMemo` → Task 3 ✅
  - `AnalysisState` + `CategorySearchResult` (carrying full `Category`) → Task 4 ✅
  - `CategorySearchDetailState` + `DatedTransactionGroup` (no echoed family-key fields) → Task 5 ✅
  - Slice providers (categories + accounts, plain `StreamProvider.autoDispose`) → Task 6 ✅
  - `AnalysisController` — debounce, generation-counter cancellation, sort, loading-with-previous, **live category updates via `ref.listen`**, **Drift `onError` forwarding**, **`build()` re-entry safety** → Task 7 ✅
  - `CategorySearchDetailController` (filter, group, empty-query guard, day boundary) → Task 8 ✅
  - `TransactionSearchRow` (read-only) → Task 9 ✅
  - `CategorySearchTile` (uses `categoryDisplayName`) → Task 10 ✅
  - `AnalysisSearchPlaceholder` → Task 11 ✅
  - `AnalysisScreen` rewrite — IME-composition guard, focus + clear unfocus, adaptive `PreferredSize`, `Semantics(liveRegion: true)`, localized error → Task 12 ✅
  - `CategorySearchDetailScreen` (uses `categoryDisplayName`, localized error) → Task 13 ✅
  - Router guards (3 widget tests, in-shell push, no `parentNavigatorKey`) → Task 14 ✅
  - l10n keys (7 keys in `app_en.arb`, `app_zh_TW.arb`, and `app_zh_CN.arb`; `app_zh.arb` remains the fallback shim) → Task 1 ✅
  - Widget tests — idle, empty, results, **back-navigation `keepAlive`**, router guards → Tasks 12, 13, 14 ✅
  - Spec § Decisions and Trade-offs is documentation-only; nothing to implement.

- **Placeholder scan:** Searched for "TBD", "fill in", "implement later", "similar to" — none found.

- **Type consistency:**
  - `CategorySearchResult.category: Category` — full value object — consistent across Task 4 (definition), Task 7 (controller emits), Task 10 (widget reads as `result.category.{id,icon,color,type}` and renders via `categoryDisplayName`).
  - `CategorySearchDetailController` family-key parameter names: `categoryId`, `query`, `currencyCode` — consistent across Task 8 (controller), Task 13 (screen passes them), and Task 14 (router parses them). They are NOT echoed in `DetailData` state.
  - `AnalysisController.updateQuery(String)` — same in Task 7 (definition) and Task 12 (screen calls it). The IME-composing guard in `_onChanged` skips dispatch while the input has an active composition range.

- **Lifecycle invariants** (controller):
  - `_debounceTimer`, `_subscription`, `_lastTransactions` cleared on every `updateQuery`.
  - `_generation` bumped on every `updateQuery`; async callbacks gate on the captured value.
  - `_lastResults` cleared on the empty-query branch (so type-after-clear doesn't render stale `previous`).
  - `_emitter?.close()` at the top of `build()` so a rebuild doesn't orphan the prior controller.
  - `repo.watchByMemo(query).listen(..., onError: ...)` forwards Drift errors to listeners.
  - `ref.listen(analysisCategoriesByIdProvider, ...)` re-runs `_group` against `_lastTransactions` on category renames / archives — no transactions emission required.

- **Accessibility / 2× text scale:**
  - `Semantics(liveRegion: true)` wrapping the body announces results/empty/error transitions.
  - SearchBar row height scales via `MediaQuery.textScalerOf(...).clamp(maxScaleFactor: 1.5)` — matches CLAUDE.md "fixed-height widgets clamp at 1.5× or reflow".

- **Test coverage** (controller-side spec items now pinned):
  - Empty-query → idle, no repo call.
  - Debounce: 3 rapid calls fire 1 subscription.
  - Sort key (date desc, id asc tiebreak).
  - Subscription cancellation via prior-stream `onCancel` spy.
  - Loading carries previous AND `verifyNever` on the new query before the second debounce fires.
  - Clear → retype emits loading with `previous: null`.
  - Category-map emission re-emits `AnalysisResults` without a new transactions emission.
  - Drift stream errors surface as `AsyncValue.error`.
  - Router guards: 4 cases (bad id, empty q, empty c, whitespace-only q).
  - Back-navigation preserves `AnalysisController` query and the SearchBar text.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-05-09-transaction-search-implementation.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

**Which approach?**
