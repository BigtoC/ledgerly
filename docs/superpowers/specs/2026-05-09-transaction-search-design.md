# Transaction Search — Design Spec

## Overview

The Analysis tab is currently a Phase 2 placeholder showing a "coming soon" icon. This spec adds memo-text transaction search as the first real feature on that tab, with a two-level drill-down: search results grouped by category (with count + sum), then tap a category to see matching transactions grouped by date.

**Goal:** A user types a search query on the Analysis page and sees matching transactions grouped by category, with the total count and sum per category. Tapping a category opens a detail page showing those transactions grouped by date, with an overall sum header.

**Acceptance criterion:** Typing "coffee" in the search bar shows categories that have transactions with "coffee" in the memo. Each category card shows "{N} transactions" and the total sum. Tapping a category card opens a detail page with those transactions grouped by date, showing per-day transaction tiles and an overall total at the top.

**Scope decisions (from brainstorming):**
- **Search scope:** Memo text only. No amount, category, or date filtering.
- **Match behavior:** Case-insensitive substring match on `memo`. Null/empty memos excluded.
- **Trigger:** Search-as-you-type with 300ms debounce.
- **Entry point:** Inline `SearchBar` at the top of the Analysis screen.
- **Idle state:** Current placeholder remains until the user types.
- **Results (Level 1):** Grouped by (category, currency) — each card shows count + total sum for that category+currency pair. A category with transactions in multiple currencies appears as multiple cards (consistent with Home's per-currency grouping).
- **Drill-down (Level 2):** Tap category → new page with matching transactions for that category grouped by date, with overall sum header.
- **Navigation:** Route carries `categoryId` as path param and `memo` query as query param.

No DB migration is required. The search feature adds one DAO method, one repository method, one controller, one state file, two screens, and l10n keys.

---

## Data Layer

### DAO Addition

`TransactionDao` (`lib/data/database/daos/transaction_dao.dart`) gains one method:

```dart
/// Watch transactions whose memo contains [query] (case-insensitive
/// substring). Returns rows ordered by `date DESC, id DESC`.
/// Transactions with `memo IS NULL` are excluded (LIKE on NULL
/// returns no match).
Stream<List<TransactionRow>> watchByMemo(String query);
```

**SQL:** `WHERE memo LIKE '%' || :query || '%' COLLATE NOCASE` — SQLite `COLLATE NOCASE` provides case-insensitive matching for ASCII characters. For full Unicode case-insensitivity (e.g., Chinese characters), SQLite's default binary collation already distinguishes codepoints, but Chinese memos don't have case variants so this is fine. The `LIKE` operator naturally excludes `NULL` memos.

**Ordering:** `date DESC, id DESC` — consistent with every other transaction query in the DAO.

**Limit:** No explicit limit. The search is user-driven and bounded by the query; the controller groups results by category so the Level 1 list is naturally small (at most one entry per category).

### Repository Addition

`TransactionRepository` (`lib/data/repositories/transaction_repository.dart`) gains one method:

```dart
/// Transactions whose memo contains [query] (case-insensitive
/// substring). Returns domain models. Used by Analysis search.
Stream<List<Transaction>> watchByMemo(String query);
```

The concrete `DriftTransactionRepository` delegates to `_dao.watchByMemo(query).asyncMap(_rowsToDomain)` — reusing the existing `_rowsToDomain` mapping helper.

No new tables, no schema change, no migration needed.

---

## State & Controller

### State

`lib/features/analysis/analysis_state.dart` — Freezed sealed union:

```dart
@freezed
sealed class AnalysisState with _$AnalysisState {
  /// No query typed yet. Shows the existing placeholder.
  const factory AnalysisState.idle() = AnalysisIdle;

  /// Debounce in progress or stream initializing. Shows spinner
  /// over the previous content (or blank on first search).
  const factory AnalysisState.loading() = AnalysisLoading;

  /// Query has matching transactions. Categories sorted by total
  /// amount descending.
  const factory AnalysisState.results({
    required List<CategorySearchResult> categories,
    required String query,
  }) = AnalysisResults;

  /// Query typed but no matching transactions.
  const factory AnalysisState.empty({
    required String query,
  }) = AnalysisEmpty;
}

@freezed
abstract class CategorySearchResult with _$CategorySearchResult {
  const factory CategorySearchResult({
    required int categoryId,
    required String categoryName,
    required IconData categoryIcon,
    required Color categoryColor,
    required CategoryType categoryType, // expense | income (Freezed enum)
    required int transactionCount,
    required int totalAmountMinorUnits,
    required String currencyCode,
  }) = _CategorySearchResult;
}
```

### Controller

`lib/features/analysis/analysis_controller.dart` — Riverpod `StreamNotifier<AnalysisState>`:

- **Dependencies:** `TransactionRepository`, `CategoryRepository`, `CurrencyRepository` (for symbol on the sum display)
- **Command:** `updateQuery(String query)` — called by the search bar's `onChanged`
- **Behavior:**
  1. Empty/whitespace query → emit `AnalysisState.idle()`
  2. Non-empty query → emit `AnalysisState.loading()`, debounce 300ms, then subscribe to `TransactionRepository.watchByMemo(query)`
  3. On each emission: group transactions by `(categoryId, currency)`, compute `count` and `totalAmountMinorUnits` per group, resolve category display fields from `CategoryRepository`
  4. If groups empty → emit `AnalysisState.empty(query)`
  5. If groups non-empty → emit `AnalysisState.results(categories: [...], query)` sorted by `totalAmountMinorUnits` descending

**Debounce implementation:** Use a `Timer` field in the controller. On each `updateQuery` call, cancel the previous timer and start a new 300ms timer that triggers the stream subscription. This avoids creating Drift stream subscriptions on every keystroke. `ref.onDispose` must cancel the timer to avoid leaks, matching the pattern in `HomeController` (`_undoTimer`).

**Category resolution:** The controller batches category lookups — collects all `categoryId` values from the transaction list, calls `CategoryRepository.getById` for each (or uses a pre-cached map from `analysisProviders.dart`), and assembles `CategorySearchResult` with the resolved display name, icon, and color. Archived categories are included in results (transactions referencing archived categories still exist and should be searchable). Display name uses `customName ?? l10n(l10nKey)` following the existing pattern.

---

## UI — Analysis Screen

`lib/features/analysis/analysis_screen.dart` — rewritten:

### Layout

```
Scaffold
  AppBar
    SearchBar (Material 3) — "Search transactions…" hint
  Body (switches on state)
    idle     → current placeholder (Icon + title + body text)
    loading  → CircularProgressIndicator (over previous content)
    results  → ListView of CategorySearchTile widgets
    empty    → Center("No transactions found")
```

### SearchBar behavior

- `onChanged` → `ref.read(analysisControllerProvider.notifier).updateQuery(value)`
- `onTap` (when already idle) → no-op (bar is always visible, not collapsed)
- Clear button (X) → resets to idle state
- No submit/search button — search-as-you-type

### CategorySearchTile widget

`lib/features/analysis/widgets/category_search_tile.dart`:

```
Card / ListTile
  Leading: category icon (colored, 40px circle)
  Title: category name (localized)
  Subtitle: "{N} transactions"
  Trailing: formatted total sum (with currency symbol, sign derived from category type)
```

- Tapping navigates to `/analysis/search/:categoryId?q=<memo>`
- Amount sign: expense → negative (red), income → positive (green) — using existing color conventions from Home

---

## UI — Category Search Detail Screen

`lib/features/analysis/category_search_detail_screen.dart` — new:

### Route

`/analysis/search/:categoryId?q=<memo>` — pushed onto the shell route navigator.

- `:categoryId` — int path parameter
- `?q=<memo>` — query parameter (URL-encoded by go_router automatically)

### Layout

```
Scaffold
  AppBar
    Title: category name
    Back button
  Body
    Header: total sum for all matching transactions in this category
    ListView (grouped by date)
      Date header: "May 9, 2026" (locale-aware)
      Transaction tiles (reused from Home)
      Per-day subtotal at end of each day group
```

### Detail Screen State & Controller

`lib/features/analysis/category_search_detail_state.dart` — Freezed sealed union:

```dart
@freezed
sealed class CategorySearchDetailState with _$CategorySearchDetailState {
  const factory CategorySearchDetailState.loading() = DetailLoading;
  const factory CategorySearchDetailState.data({
    required List<DatedTransactionGroup> days,
    required int overallSumMinorUnits,
    required String currencyCode,
    required String query,
    required int categoryId,
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

`lib/features/analysis/category_search_detail_controller.dart` — `@riverpod` `StreamNotifier` family keyed on `(int categoryId, String memo)`:

- **Dependencies:** `TransactionRepository`, `AccountRepository` (for tile display)
- **Behavior:**
  1. Subscribe to `TransactionRepository.watchByMemo(memo)`
  2. Filter to `transaction.categoryId == categoryId`
  3. Group by `DateHelpers.startOfDay(transaction.date)`
  4. Compute per-day sums and overall sum
  5. Emit `DetailData` with sorted day groups, or `DetailEmpty` if no matches

### Transaction tiles

Reuse the existing transaction tile widget from Home (`lib/features/home/widgets/`). Each tile shows: category icon, memo, amount, account. The detail controller resolves accounts via `AccountRepository` (batch lookup by account IDs). Tapping a tile navigates to `/home/edit/:id` for editing.

---

## Routing

`lib/app/router.dart` additions:

```dart
GoRoute(
  path: 'search/:categoryId',
  builder: (context, state) {
    final categoryId = int.tryParse(state.pathParameters['categoryId'] ?? '');
    if (categoryId == null) return const AnalysisScreen(); // guard
    final memo = state.uri.queryParameters['q'] ?? '';
    return CategorySearchDetailScreen(
      categoryId: categoryId,
      query: memo,
    );
  },
),
```

This route lives under the `/analysis` shell branch. Navigation uses `context.push` from the Analysis screen so the Analysis tab's search state is preserved when navigating back.

---

## l10n

New keys in `app_en.arb`, `app_zh_TW.arb`, `app_zh_CN.arb`:

| Key                        | English                                                               | zh-TW         | zh-CN         |
|----------------------------|-----------------------------------------------------------------------|---------------|---------------|
| `analysisSearchHint`       | Search transactions…                                                  | 搜尋交易紀錄…       | 搜索交易记录…       |
| `analysisNoResults`        | No transactions found                                                 | 找不到交易紀錄       | 未找到交易记录       |
| `analysisTransactionCount` | `{count,plural, =1{{count} transaction} other{{count} transactions}}` | `{count} 筆交易` | `{count} 笔交易` |
| `analysisSearchTotal`      | Total                                                                 | 總計            | 总计            |

`analysisTransactionCount` uses ICU plural syntax for English (`=1` singular, `other` plural). Chinese locales use a single form (no plural distinction), so the zh-TW/zh-CN entries use a simple `{count}` placeholder.

---

## File Summary

### New files

| File                                                                    | Layer       | Purpose                              |
|-------------------------------------------------------------------------|-------------|--------------------------------------|
| `lib/features/analysis/analysis_state.dart`                             | UI / state  | Freezed state union                  |
| `lib/features/analysis/analysis_controller.dart`                        | UI / state  | StreamNotifier with debounce         |
| `lib/features/analysis/analysis_providers.dart`                         | UI / state  | Slice-local category lookup provider |
| `lib/features/analysis/category_search_detail_state.dart`               | UI / state  | Detail screen Freezed state          |
| `lib/features/analysis/category_search_detail_controller.dart`          | UI / state  | Detail screen family StreamNotifier  |
| `lib/features/analysis/category_search_detail_screen.dart`              | UI / widget | Drill-down page                      |
| `lib/features/analysis/widgets/category_search_tile.dart`               | UI / widget | Category result card                 |
| `test/unit/controllers/analysis_controller_test.dart`                   | Test        | Controller unit tests                |
| `test/unit/controllers/category_search_detail_controller_test.dart`     | Test        | Detail controller unit tests         |
| `test/widget/features/analysis/analysis_screen_test.dart`               | Test        | Screen widget tests                  |
| `test/widget/features/analysis/category_search_detail_screen_test.dart` | Test        | Detail screen widget tests           |

### Modified files

| File                                                | Change                                           |
|-----------------------------------------------------|--------------------------------------------------|
| `lib/data/database/daos/transaction_dao.dart`       | Add `watchByMemo`                                |
| `lib/data/repositories/transaction_repository.dart` | Add `watchByMemo`                                |
| `lib/features/analysis/analysis_screen.dart`        | Rewrite (SearchBar + state-driven body)          |
| `lib/app/router.dart`                               | Add `search/:categoryId` route under `/analysis` |
| `l10n/app_en.arb`                                   | Add 4 new keys                                   |
| `l10n/app_zh_TW.arb`                                | Add 4 new keys                                   |
| `l10n/app_zh_CN.arb`                                | Add 4 new keys                                   |

No schema migration. No new dependencies.

---

## Testing Strategy

### Unit tests

- **AnalysisController:** Mock `TransactionRepository.watchByMemo` to return controlled streams. Verify:
  - Empty query → `idle` state
  - Query with matches → `results` state with correct grouping, count, sum
  - Query with no matches → `empty` state
  - Debounce: rapid query updates only trigger one stream subscription after 300ms
  - Category resolution: correct name, icon, color from mocked `CategoryRepository`

### Widget tests

- **AnalysisScreen:** Verify search bar renders, placeholder shown on idle, results list on query, empty message on no match. Verify category tile tap navigates to detail route.
- **CategorySearchDetailScreen:** Verify grouped-by-date layout, overall sum header, transaction tiles render correctly. Verify back navigation preserves Analysis search state.

### Integration tests

- Not required for this feature (no cross-feature orchestration, no schema migration). The widget tests with Drift in-memory DB cover the data→UI flow adequately.

---

## Decisions and Trade-offs

### Why memo-only search?

Amount and category filtering add UI complexity (filter chips, range pickers) that isn't justified for the first search feature. Memo text covers the most common use case: "find that coffee transaction." Amount/category filters can be added later as filter chips on the search bar without changing the architecture.

### Why Dart grouping instead of SQL GROUP BY?

The existing codebase groups transactions in Dart at the controller level (e.g., `HomeController` groups by date). Following this pattern keeps the DAO simple (one `watchByMemo` method) and the grouping logic testable in controller tests. For a local-first app, the data volume is small enough that in-memory grouping has no measurable performance impact.

### Why a separate detail screen instead of expanding inline?

A drill-down page gives full vertical space to the date-grouped transaction list and allows the user to use the back button to return to category results. An inline expansion (accordion-style) would make the category list scroll position confusing and limit the detail view's space.

### Why query params for the memo in the route?

The memo is free-text that can contain slashes, spaces, and Unicode characters. Query parameters (`?q=memo`) are URL-encoded automatically by go_router and avoid path parsing issues. The `categoryId` is a simple int and works as a path parameter.

### Why no result count limit?

The search is user-driven (they type a specific query) and the results are grouped by category (typically 1-5 categories match a query). There's no need for pagination at either level. If the user has thousands of transactions matching "coffee," the category grouping naturally compresses them into a handful of category cards.
