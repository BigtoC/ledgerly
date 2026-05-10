# Transaction Search — Design Spec

## Overview

The Analysis tab is currently a Phase 2 placeholder showing a "coming soon" icon. This spec adds memo-text transaction search as the first real feature on that tab, with a two-level drill-down: search results grouped by category (with count + sum), then tap a category to see matching transactions grouped by date.

**Goal:** A user types a search query on the Analysis page and sees matching transactions grouped by category, with the total count and sum per category. Tapping a category opens a detail page showing those transactions grouped by date, with an overall sum header.

**Acceptance criterion:** Typing "coffee" in the search bar shows one card per `(category, currency)` pair with at least one matching transaction. Each card shows "{N} transactions" (via `analysisTransactionCount` plural key) and the per-pair total sum, formatted in that currency. A category that has matching coffee transactions in both USD and EUR appears as two cards. Tapping a card opens a detail page filtered to that exact `(categoryId, currencyCode)` pair, with transactions grouped by date and a single-currency overall total at the top.

**Scope decisions (from brainstorming):**
- **Search scope:** Memo text only. No amount, category, or date filtering.
- **Match behavior:** Case-insensitive substring match on `memo`. Null/empty memos excluded.
- **Trigger:** Search-as-you-type with 300ms debounce.
- **Entry point:** Inline `SearchBar` at the top of the Analysis screen.
- **Idle state:** A search-prompt placeholder (search icon + `analysisSearchPrompt` copy) replaces the current "Phase 2 coming soon" copy. The new copy must hint at what the bar searches (memos), not just "type to search".
- **Results (Level 1):** Grouped by (category, currency) — each card shows count + total sum for that category+currency pair. A category with transactions in multiple currencies appears as multiple cards (consistent with Home's per-currency grouping).
- **Drill-down (Level 2):** Tap category → new page with matching transactions for that category grouped by date, with overall sum header.
- **Navigation:** Route path is `/analysis/search/:categoryId` (path param) plus required query parameters `?q=<query>&c=<currencyCode>`. All three are required to render the detail page; missing/empty values fall back to the search list (see Routing § for the rationale and the guard implementation).

No DB migration is required. The search feature adds one DAO method, one repository method, two controllers (search list + detail family), two state files, two screens, slice-local providers, and l10n keys.

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

**Empty-query guard:** The DAO short-circuits when `query` is empty or whitespace-only (returns `Stream.value(const [])`) — without it, `LIKE '%%'` matches every memoed transaction in the DB, which would make a deep-linked detail route (`/analysis/search/5?q=&c=USD`) silently dump every USD transaction in category 5. Belt-and-suspenders: the AnalysisController also short-circuits on empty query (emits `idle`) before reaching the repository.

**Ordering:** `date DESC, id DESC` — consistent with every other transaction query in the DAO.

**Limit:** No explicit limit. The search is user-driven and bounded by the query; the controller groups results by category so the Level 1 list is naturally small (at most one entry per category+currency pair).

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
  /// No query typed yet. Shows the search-prompt placeholder.
  const factory AnalysisState.idle() = AnalysisIdle;

  /// Query is being debounced or the underlying stream is re-subscribing
  /// after a query change. `previous` carries the last [AnalysisResults]
  /// payload so the UI can keep rendering it under a spinner overlay
  /// rather than blanking; `null` on the first search when no prior
  /// results exist.
  const factory AnalysisState.loading({
    required String query,
    List<CategorySearchResult>? previous,
  }) = AnalysisLoading;

  /// Query has matching transactions. Categories sorted by most-recent
  /// matching transaction date (descending).
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
    required String categoryIconKey,    // resolved at the widget via iconForKey()
    required int categoryColorIndex,    // resolved at the widget via colorForIndex()
    required CategoryType categoryType, // expense | income (Freezed enum)
    required int transactionCount,
    required int totalAmountMinorUnits,
    required Currency currency,         // full value object — formatter needs decimals + symbol
    required DateTime mostRecentDate,   // max(transaction.date) within this (cat, currency) group; primary sort key
  }) = _CategorySearchResult;
}
```

### Controller

`lib/features/analysis/analysis_controller.dart` — Riverpod `StreamNotifier<AnalysisState>`:

- **Annotation:** `@Riverpod(keepAlive: true, dependencies: [transactionRepository])` — mirrors `HomeController:57`. `keepAlive: true` lets the typed query and result list survive navigation to the detail screen and back. The slice-local `analysisCategoriesByIdProvider` is also `ref.watch`ed but is a plain `StreamProvider.autoDispose` (no `@Riverpod` annotation, see Slice-local providers below) — `dependencies:` lists only generator-annotated direct watch targets, matching codebase convention in `repository_providers.dart`.
- **Dependencies (runtime):** `transactionRepositoryProvider` (direct watch) and `analysisCategoriesByIdProvider` (direct watch — the controller composes both streams to do its grouping). `Currency` display data is already populated on `Transaction.currency` by `_rowsToDomain`, so no `CurrencyRepository` is needed. `AccountRepository` is *not* a controller dependency — account display is resolved widget-side via the slice provider, see UI section.
- **Command:** `updateQuery(String query)` — called by the search bar's `onChanged`.
- **Behavior:**
  1. Empty/whitespace query → cancel any in-flight debounce timer and any active Drift stream subscription, emit `AnalysisState.idle()`. The DAO also short-circuits on empty input (belt-and-suspenders).
  2. Non-empty query → cancel any prior debounce timer **and any prior `watchByMemo` stream subscription** (so a slow query 'co' can't leak emissions onto a faster 'coffee' result). Emit `AnalysisState.loading(query: query, previous: lastResults)` — `lastResults` is the most recent `AnalysisResults.categories` from this notifier, or `null` if none. Start a 300ms `Timer`; on fire, subscribe to `TransactionRepository.watchByMemo(query)`.
  3. On each emission: build `(categoryId, currencyCode) → bucket` accumulator computing `transactionCount`, `totalAmountMinorUnits`, and `mostRecentDate` (max `transaction.date` per bucket). Resolve each bucket's category from the latest emission of `analysisCategoriesByIdProvider`; resolve `Currency` from the bucket's first transaction (every transaction in the bucket shares a currency by construction).
  4. If buckets empty → emit `AnalysisState.empty(query)`.
  5. Otherwise → emit `AnalysisState.results(categories: [...], query)` sorted by `mostRecentDate` descending. Sort by date (not amount) avoids cross-currency comparison entirely (JPY 0-decimal vs USD 2-decimal raw integers aren't comparable) and surfaces recently-active categories first, matching user intent — they're usually searching for something they transacted recently. Tie-break by `categoryId` ascending for stable ordering.

**Debounce + cancellation:** Two resources need disposal on every `updateQuery`: the pending `Timer` and the active `StreamSubscription` from the prior `watchByMemo`. Both are stored as nullable fields on the notifier and explicitly cancelled in `_onQueryChanged` and again in `ref.onDispose` to avoid leaks. This follows the same lifecycle discipline as `HomeController._undoTimer` but adds the stream-subscription axis because Analysis re-subscribes per query (Home keeps a single subscription for `selectedDay` updates).

**Category resolution:** `analysisCategoriesByIdProvider` (defined below) is a live `StreamProvider<Map<int, Category>>` backed by `categoryRepository.watchAll(includeArchived: true)`. The controller composes this map with each `watchByMemo` emission so category renames or archive toggles flow through to active search results without restarting the search. For each bucket, the controller looks up `Category` and copies `categoryIconKey` (registry key) and `categoryColorIndex` (palette index) onto the result — the widget resolves these to `IconData`/`Color` at render time via `iconForKey` / `colorForIndex`. Archived categories are included so transactions referencing archived categories remain searchable. Display name uses `customName ?? l10n(l10nKey)`, matching the existing pattern in `TransactionTile`. **Why controller-side (not widget-side as in Home):** Analysis groups *by* category, so the controller needs the category map to compute its sort key (`mostRecentDate`) and to materialize one `CategorySearchResult` per `(categoryId, currency)` pair. Home, by contrast, emits raw `Transaction` rows and lets the widget resolve display fields per-tile.

### Slice-local providers (`analysis_providers.dart`)

```dart
/// `id → Category` lookup (active + archived) — mirrors
/// `homeCategoriesByIdProvider`. Plain provider (no `@Riverpod`) to
/// match `home_providers.dart` style. Stays alive while any active
/// watcher exists; `analysisControllerProvider` (`keepAlive: true`)
/// keeps it alive for the lifetime of the Analysis tab session.
final analysisCategoriesByIdProvider =
    StreamProvider.autoDispose<Map<int, Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo
      .watchAll(includeArchived: true)
      .map((rows) => {for (final c in rows) c.id: c});
});

/// `id → Account` lookup (active + archived) for the detail screen's
/// transaction tiles. Same shape as `homeAccountsByIdProvider`.
/// Co-located here rather than reused from `home_providers.dart` so
/// the Analysis slice doesn't import from the Home feature.
final analysisAccountsByIdProvider =
    StreamProvider.autoDispose<Map<int, Account>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo
      .watchAll(includeArchived: true)
      .map((rows) => {for (final a in rows) a.id: a});
});
```

Both providers live-stream so category renames / archive toggles and account renames propagate to active search results and detail pages without restarting the search.

---

## UI — Analysis Screen

`lib/features/analysis/analysis_screen.dart` — rewritten:

### Layout

```
Scaffold
  AppBar
    title: Text(l10n.analysisTitle)
    bottom: PreferredSize(
      child: Padding(EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SearchBar(  // Material 3 inline variant — no SearchAnchor overlay
          hintText: l10n.analysisSearchHint,
          leading: Icon(Icons.search),
          trailing: [if (query.isNotEmpty) IconButton(Icons.clear, onClear)],
        ),
      ),
    )
  Body (switches on AnalysisState):
    AnalysisIdle      → AnalysisSearchPlaceholder (Icon + analysisSearchPrompt copy)
    AnalysisLoading   → if (state.previous != null)
                          Stack(ListView(state.previous), centered spinner)
                        else
                          Center(CircularProgressIndicator())
    AnalysisResults   → ListView.builder(state.categories → CategorySearchTile)
    AnalysisEmpty     → Center(Text(l10n.analysisNoResults))
```

The `SearchBar` lives in `AppBar.bottom:` (a `PreferredSize`), not in the `title:` slot — Material 3's inline `SearchBar` has its own padding/elevation that fights with `AppBar.title`'s constraints. Using `bottom:` keeps the search field visually anchored to the AppBar and survives 2× text scale because `PreferredSize` reports the larger of two intrinsic heights.

### SearchBar behavior

- `onChanged: (value) => ref.read(analysisControllerProvider.notifier).updateQuery(value)`
- `onTap`: not used — this is an inline `SearchBar`, not a `SearchAnchor`, so there is no overlay to open.
- Clear: a custom trailing `IconButton(Icons.clear)` shown only when the local `TextEditingController.text` is non-empty. Tapping clears the text controller and calls `updateQuery('')`, which cancels any in-flight stream/timer and emits `AnalysisState.idle()`.
- No submit/search button — search-as-you-type via `onChanged` + 300ms debounce in the controller.

### CategorySearchTile widget

`lib/features/analysis/widgets/category_search_tile.dart`:

```
Card / ListTile
  Leading: 40px circle, color = colorForIndex(result.categoryColorIndex),
           icon  = iconForKey(result.categoryIconKey)
  Title:    result.categoryName (already resolved with customName ?? l10n)
  Subtitle: l10n.analysisTransactionCount(result.transactionCount)  // ICU plural
  Trailing: MoneyFormatter.format(
              minorUnits: signForType(result.categoryType) * result.totalAmountMinorUnits,
              currency:   result.currency,
            )
```

- Tapping navigates to `/analysis/search/:categoryId?q=<query>&c=<currency.code>`. Both `q` and `c` come from the tile's `CategorySearchResult` — each tile represents one `(category, currency)` pair, so the detail page filters by both to keep the "overall sum" header in a single currency.
- Amount sign: expense → negative (red), income → positive (green) — same `signForType` / color conventions used by Home's `TransactionTile`. Reuse the existing helper rather than re-deriving signs at the widget.

---

## UI — Category Search Detail Screen

`lib/features/analysis/category_search_detail_screen.dart` — new:

### Route

Path: `/analysis/search/:categoryId` (registered as a child route of the `/analysis` shell branch). The search string and currency are passed as URL query parameters, not as part of the path.

- `:categoryId` — int path parameter; required
- `?q=<query>` — URL query parameter; required and non-empty (URL-encoded by go_router automatically). An empty `q` is treated as a broken deep-link and falls back to `AnalysisScreen`, because `LIKE '%%'` would otherwise dump every `(category, currency)` transaction on the detail page.
- `?c=<currencyCode>` — URL query parameter; required and non-empty. Without it, the detail's overall-sum header would mix currencies. Same fallback to `AnalysisScreen` if missing.

### Layout

```
Scaffold
  AppBar
    Title: category name
    Back button
  Body (wrapped in SlidableAutoCloseBehavior so an open swipe-action
        on one row collapses when another row's swipe begins)
    Header: signForType * overallSumMinorUnits formatted via MoneyFormatter
            using state.currency (single-currency by construction).
            Color matches Level 1 (expense → red, income → green).
            The pending-delete row is excluded from this sum during the
            4-second undo window so the header stays consistent with what
            the user can see.
    ListView (grouped by date)
      Date header: DateFormat.yMMMd(locale).format(date)
      Transaction rows (TransactionSearchRow with onTap → push
        `/home/edit/$id` and onDelete → controller.deleteTransaction(id)).
      Per-day subtotal: signForType * day.daySumMinorUnits formatted in state.currency,
                        same sign/color rules as Level 1.

  SnackBar (transient, surfaced by the screen on pendingDelete null→set transitions)
    "Transaction deleted" + UNDO action (kUndoWindow = 4s).
```

**Edit gesture:** primary tap pushes `/home/edit/$id`. The route is registered under the home branch with `parentNavigatorKey: _rootNavigatorKey`, so it overlays the analysis branch correctly. The detail screen does *not* re-pin or re-query on return — the underlying memo stream re-emits naturally, and a saved transaction whose memo no longer matches the active query simply drops out of the list.

**Delete gesture:** end-swipe (or tapping the swipe action) calls `deleteTransaction(id)` on the detail controller, which sets `pendingDelete`, hides the row optimistically, schedules a `kUndoWindow` timer, and surfaces the undo SnackBar. The repository write only happens when the timer fires; tapping UNDO before then cancels the timer with no DB write. A delete-failure surfaces a generic-error SnackBar via `setEffectListener` (mirrors Home).

### Detail Screen State & Controller

`lib/features/analysis/category_search_detail_state.dart` — Freezed sealed union:

```dart
@freezed
sealed class CategorySearchDetailState with _$CategorySearchDetailState {
  const factory CategorySearchDetailState.loading() = DetailLoading;
  const factory CategorySearchDetailState.data({
    required List<DatedTransactionGroup> days,
    required int overallSumMinorUnits,
    required Currency currency, // full descriptor — formatter needs decimals + symbol
    /// Non-null while a row is in its 4-second undo window. The matching
    /// transaction is filtered out of [days] and excluded from
    /// [overallSumMinorUnits] so the UI hides it optimistically until
    /// the timer commits or the user taps Undo.
    CategorySearchPendingDelete? pendingDelete,
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

/// Plain class — controller swaps it out by reference. Mirrors
/// `home/home_state.dart`'s `PendingDelete`; declared locally so the
/// analysis slice does not import from the home feature.
class CategorySearchPendingDelete {
  const CategorySearchPendingDelete({
    required this.transaction,
    required this.scheduledFor,
  });

  final Transaction transaction;
  final DateTime scheduledFor;
}
```

`lib/features/analysis/category_search_detail_controller.dart` — `@riverpod` family keyed on `(int categoryId, String query, String currencyCode)`:

- **Annotation:** `@Riverpod(keepAlive: true, dependencies: [transactionRepository, AnalysisController])`. `keepAlive: true` is required because the controller owns a 4-second undo timer that must survive trivial rebuilds while the user considers tapping Undo on the snackbar.
- **Dependencies (runtime):** `transactionRepositoryProvider` (direct watch) and `analysisControllerProvider` (read-only, for the hot-path cache of `lastTransactions` when navigating from a settled search). The detail controller does *not* depend on `AccountRepository` or `CategoryRepository` — both are widget-side concerns: `TransactionSearchRow` takes `Account?` / `Category?` directly, and the detail screen resolves them via `analysisAccountsByIdProvider` and `analysisCategoriesByIdProvider`. The detail controller only needs `Transaction` rows.
- **Currency in state:** the route's `currencyCode` string is upgraded to a full `Currency` value object inside the controller by reading the first emission's `transaction.currency` (every matching transaction shares the currency by construction of step 2's filter). If no transaction matches, the state is `DetailEmpty` and the AppBar header carries no sum.
- **Internal state held across rebuilds:** `_emitter` (StreamController), `_subscription` (the active `watchByMemo` subscription), `_undoTimer`, `_pendingDelete`, `_committedDeleteIds` (suppresses the about-to-be-removed row between commit-time and the next stream emission), `_lastTransactions` (cache so `_emitFromCache` can re-emit synchronously on `deleteTransaction` / `undoDelete` without waiting for a fresh repo emission), `_effectListener` (set by the screen for one-shot delete-failure notifications). All resources are cancelled / cleared in `ref.onDispose` and at the top of `build()` to prevent leaks across rebuilds.
- **Behavior:**
  1. Subscribe to `TransactionRepository.watchByMemo(query)` (or reuse `analysisControllerProvider.notifier.lastTransactions` when the parent screen has settled results for the same query). Guard: if `query` is empty/whitespace at family-key time, the controller emits `DetailEmpty` immediately and never subscribes (matches the router's empty-`q` guard, defense-in-depth).
  2. Filter to `transaction.categoryId == categoryId && transaction.currency.code == currencyCode && !committedDeleteIds.contains(t.id) && t.id != pendingDelete?.transaction.id`. The pending-delete and committed-delete filters are belt-and-suspenders: they hide the row optimistically the instant the user swipes, even before the repo's next emission lands.
  3. Group by `DateHelpers.startOfDay(transaction.date)`.
  4. Compute per-day sums and overall sum (single-currency by construction — step 2 already filtered).
  5. Emit `DetailData` with sorted day groups, or `DetailEmpty` if no matches. Days are sorted by date descending (most recent first), matching DAO ordering and the Level 1 sort. Within each day, transactions retain DAO order (`date DESC, id DESC`).
- **Commands:**
  - `deleteTransaction(int id)` — sets `_pendingDelete`, re-emits the (filtered) state immediately, and starts a `kUndoWindow` timer. On expiry, calls `repo.delete(id)`. A second `deleteTransaction` call while a delete is already pending commits the prior one immediately and starts a fresh timer for the new id (mirrors `HomeController.deleteTransaction`). On commit failure, surfaces a `CategorySearchDetailDeleteFailedEffect` via `_effectListener` and re-emits with the row restored.
  - `undoDelete()` — cancels the pending timer, clears `_pendingDelete`, and re-emits from `_lastTransactions` so the row reappears synchronously. Repository is never touched.
  - `setEffectListener(listener)` — single-listener slot used by the screen to hook delete-failure SnackBars (mirrors `HomeController.setEffectListener`).

### Transaction tiles

Search-result rows on the detail screen support **primary tap → edit** and **swipe → delete with 4-second undo**, mirroring Home's `TransactionTile` UX so the two surfaces feel consistent. They deliberately do **not** expose the duplicate / overflow-menu surface — duplicating from a filtered view is rarely meaningful, and adding it would balloon the row's affordances. The Level 1 search tile (the per-`(category, currency)` card on the search list) remains read-only — only Level 2 transaction rows are interactive.

Reusing Home's `TransactionTile` directly is rejected because:
1. `TransactionTile` requires a non-null `onDuplicate`, but the detail screen has no duplicate affordance.
2. `TransactionTile`'s `Slidable` uses `groupTag: 'home'`, which would couple `SlidableAutoCloseBehavior` across the two surfaces and produce bugs when both screens stack on the navigator.
3. The detail row's edit gesture pushes `/home/edit/$id` onto the root navigator and discards the returned `Transaction` (the underlying memo stream re-emits naturally), whereas Home pins the saved day on return — the callbacks are not interchangeable.

A dedicated `TransactionSearchRow` keeps the analysis slice's interaction surface independently controllable.

`lib/features/analysis/widgets/transaction_search_row.dart` — interactive presentational widget:

```dart
class TransactionSearchRow extends StatelessWidget {
  const TransactionSearchRow({
    super.key,
    required this.transaction,
    required this.category,
    required this.account,
    required this.locale,
    this.onTap,
    this.onDelete,
  });

  final Transaction transaction;
  final Category? category; // resolved via analysisCategoriesByIdProvider
  final Account?  account;  // resolved via analysisAccountsByIdProvider
  final String    locale;

  /// Primary tap. When null the row renders without an `onTap` (read-only).
  final VoidCallback? onTap;

  /// End-swipe gesture. When null the swipe affordance is omitted entirely.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    // ListTile (with optional onTap), wrapped in a Slidable when onDelete
    // is provided. groupTag: 'analysis_search' so SlidableAutoCloseBehavior
    // is scoped to the detail screen and does not cross-fight Home's
    // `groupTag: 'home'`. Visual layout (leading icon, title, subtitle =
    // "account • memo", trailing signed amount with type-driven color)
    // matches Home's TransactionTile.
    // Amount formatting reuses MoneyFormatter.formatSigned with sign
    // derived from category.type (same switch as TransactionTile).
  }
}
```

Both callbacks are nullable so the widget can degrade to a fully read-only tile in tests or future contexts (e.g. a settings preview) without forking the implementation.

The amount-formatting logic is identical to `TransactionTile`'s `switch (cat?.type)` block. Either:
- Duplicate the 10-line switch (acceptable — three lines is not abstraction-worthy, ten arguably is) — **preferred for now**, or
- Extract `MoneyFormatter.signedAmount(transaction, category, locale)` and call it from both. Defer until a third caller appears.

No changes required to `TransactionTile` or to the Home feature.

---

## Routing

`lib/app/router.dart` additions:

```dart
GoRoute(
  path: 'search/:categoryId',
  builder: (context, state) {
    final categoryId = int.tryParse(state.pathParameters['categoryId'] ?? '');
    final query = state.uri.queryParameters['q']?.trim() ?? '';
    final currencyCode = state.uri.queryParameters['c'] ?? '';
    // All three of `categoryId`, `query`, `currencyCode` are required:
    //   - missing categoryId → no filter to apply
    //   - empty query        → would dump every (cat, currency) transaction (LIKE '%%')
    //   - missing currency   → detail's overall-sum header would mix currencies
    // Fall back to the search list rather than render a broken detail.
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
```

This route lives under the `/analysis` shell branch. Navigation uses `context.push` from the Analysis screen so the Analysis tab's search state is preserved when navigating back.

---

## l10n

New keys in `app_en.arb`, `app_zh.arb`, `app_zh_TW.arb`, `app_zh_CN.arb` (the base `app_zh.arb` is required — see `CLAUDE.md` Dependency Pins):

| Key                        | English                                                               | zh / zh-TW / zh-CN                            |
|----------------------------|-----------------------------------------------------------------------|-----------------------------------------------|
| `analysisTitle`            | Analysis                                                              | 分析 / 分析 / 分析                                  |
| `analysisSearchHint`       | Search transactions…                                                  | 搜尋交易… / 搜尋交易紀錄… / 搜索交易记录…                     |
| `analysisSearchPrompt`     | Search memos to find past transactions                                | 搜尋備註以尋找過往交易 / 搜尋備註以尋找過往交易 / 搜索备注以查找过往交易       |
| `analysisNoResults`        | No transactions found                                                 | 找不到交易 / 找不到交易紀錄 / 未找到交易记录                     |
| `analysisTransactionCount` | `{count,plural, =1{{count} transaction} other{{count} transactions}}` | `{count} 筆交易` / `{count} 筆交易` / `{count} 笔交易` |
| `analysisSearchTotal`      | Total                                                                 | 總計 / 總計 / 总计                                  |

`analysisTransactionCount` uses ICU plural syntax for English (`=1` singular, `other` plural). Chinese locales have a single form (no plural distinction), so the zh / zh-TW / zh-CN entries use a simple `{count}` placeholder. ARB plural keys may differ in placeholder form per locale provided the placeholder *names* match — the codegen treats each ARB independently.

---

## File Summary

### New files

| File                                                                    | Layer       | Purpose                                                                |
|-------------------------------------------------------------------------|-------------|------------------------------------------------------------------------|
| `lib/features/analysis/analysis_state.dart`                             | UI / state  | Freezed state union (`idle`, `loading{previous?}`, `results`, `empty`) |
| `lib/features/analysis/analysis_controller.dart`                        | UI / state  | `StreamNotifier` with debounce + stream-subscription cancellation      |
| `lib/features/analysis/analysis_providers.dart`                         | UI / state  | `analysisCategoriesByIdProvider`, `analysisAccountsByIdProvider`       |
| `lib/features/analysis/category_search_detail_state.dart`               | UI / state  | Detail screen Freezed state + `CategorySearchPendingDelete` plain class |
| `lib/features/analysis/category_search_detail_controller.dart`          | UI / state  | Detail screen family `StreamNotifier` with 4s undo window               |
| `lib/features/analysis/category_search_detail_screen.dart`              | UI / widget | Drill-down page (tap → edit, swipe → delete with undo)                  |
| `lib/features/analysis/widgets/category_search_tile.dart`               | UI / widget | Category result card                                                    |
| `lib/features/analysis/widgets/transaction_search_row.dart`             | UI / widget | Transaction row with optional `onTap` / `onDelete` for the detail screen |
| `lib/features/analysis/widgets/analysis_search_placeholder.dart`        | UI / widget | Idle-state prompt (replaces Phase 2 placeholder)                       |
| `test/unit/controllers/analysis_controller_test.dart`                   | Test        | Controller unit tests                                                  |
| `test/unit/controllers/category_search_detail_controller_test.dart`     | Test        | Detail controller unit tests                                           |
| `test/unit/repositories/transaction_repository_search_test.dart`        | Test        | DAO/repo `watchByMemo` (incl. empty-query short-circuit)               |
| `test/widget/features/analysis/analysis_screen_test.dart`               | Test        | Screen widget tests                                                    |
| `test/widget/features/analysis/category_search_detail_screen_test.dart` | Test        | Detail screen widget tests                                             |

### Modified files

| File | Change |
|---|---|
| `lib/data/database/daos/transaction_dao.dart` | Add `watchByMemo` (with empty-query short-circuit) |
| `lib/data/repositories/transaction_repository.dart` | Add `watchByMemo` returning `Stream<List<Transaction>>` |
| `lib/features/analysis/analysis_screen.dart` | Rewrite (SearchBar + state-driven body) |
| `lib/app/router.dart` | Add `search/:categoryId` route under `/analysis` with `q`/`c` guards |
| `l10n/app_en.arb` | Add 6 new keys (`analysisTitle`, `analysisSearchHint`, `analysisSearchPrompt`, `analysisNoResults`, `analysisTransactionCount`, `analysisSearchTotal`) |
| `l10n/app_zh.arb` | Add same 6 keys (base zh required by `flutter_localizations`) |
| `l10n/app_zh_TW.arb` | Add same 6 keys |
| `l10n/app_zh_CN.arb` | Add same 6 keys |

No schema migration. No new dependencies.

---

## Testing Strategy

### Repository / DAO tests

- **`watchByMemo` empty-query short-circuit:** an empty/whitespace query emits `[]` immediately and never executes the underlying SQL `LIKE '%%'` (verified by spy or by asserting no rows even when the seeded DB has 100 memoed transactions).
- **Case-insensitive match:** memos `Coffee`, `COFFEE`, `coffee shop` all match `coffee`.
- **NULL memo exclusion:** transactions with `memo IS NULL` never appear in results.
- **Ordering:** results are `date DESC, id DESC`.

### Unit tests

- **AnalysisController:** override `transactionRepositoryProvider` with a `Mock` and `analysisCategoriesByIdProvider` with a stub map. Verify:
  - Empty query → `AnalysisIdle`. Repository is never called.
  - Query → `AnalysisLoading(query: 'co', previous: null)` immediately, then `AnalysisResults` after 300ms with grouping by `(categoryId, currency)`.
  - Sort key: `mostRecentDate` desc, with `categoryId` asc tiebreak — assert by setting up two buckets where the older `mostRecentDate` has a smaller `categoryId` to ensure date wins, not id.
  - **Debounce:** rapid `updateQuery('c'), updateQuery('co'), updateQuery('cof')` within 300ms triggers exactly one stream subscription on the repo mock.
  - **Subscription cancellation:** when `updateQuery('coffee')` lands while a 'co' stream subscription is active, the prior subscription's `cancel()` is invoked before the new one is opened. Use a `StreamController` with a `onCancel` spy.
  - **Loading carries previous:** after a successful query produces `results`, a follow-up `updateQuery('xyz')` emits `AnalysisLoading(previous: <prior categories>)`, not `previous: null`.
  - **Category live-update:** while results are showing, an emission from the category stream (rename or archive) propagates to `categoryName` / `categoryIconKey` without a new transaction emission.
  - Query with no matches → `AnalysisEmpty(query)`.
- **CategorySearchDetailController:** override `transactionRepositoryProvider`. Verify:
  - Filters by both `categoryId` and `currency.code` — a transaction with the right category but wrong currency is excluded.
  - Empty `query` family-key emits `DetailEmpty` and never subscribes.
  - Per-day grouping uses `DateHelpers.startOfDay`; transactions at 23:59 and 00:01 of different days fall into different groups.
  - Day groups are date-desc; within a day, transaction order matches DAO order.
  - **Optimistic delete:** `deleteTransaction(id)` immediately re-emits a `DetailData` whose `days` exclude `id`, whose `overallSumMinorUnits` excludes that transaction's amount, and whose `pendingDelete` is non-null. The repository's `delete` is NOT called synchronously.
  - **Undo cancels:** `undoDelete()` before the timer expires re-emits with the row restored and never calls `repo.delete`.
  - **Commit on timer:** after `kUndoWindow` with no Undo, `repo.delete(id)` is called exactly once. A failed commit (mock throws) surfaces a `CategorySearchDetailDeleteFailedEffect` via the registered `_effectListener` and re-emits with the row restored.
  - **Second delete commits prior:** while a delete is pending, calling `deleteTransaction(otherId)` commits the prior pending delete immediately and starts a fresh timer for `otherId` (no clobber).

### Widget tests

- **AnalysisScreen:** search bar renders in `AppBar.bottom`; idle shows `analysisSearchPrompt` placeholder; loading-with-previous shows the previous list under a centered spinner; results list renders one tile per `(category, currency)` pair; empty shows `analysisNoResults`; category tile tap calls `context.push('/analysis/search/:id?q=…&c=…')`.
- **CategorySearchDetailScreen:** grouped-by-date layout; overall sum header uses `state.currency` for symbol+decimals; per-day subtotal sign matches Level 1; back navigation returns to `AnalysisResults` with the same query (verifies `keepAlive` on the list controller). Tapping a row pushes `/home/edit/$id` (assert via a `MockGoRouter` or `Navigator` observer). End-swiping a row hides it from the list and surfaces the undo SnackBar with `commonUndo` action; tapping UNDO restores the row before any repo write; letting the SnackBar expire commits the delete.
- **Router guards:** push `/analysis/search/abc?q=coffee&c=USD` (bad id) → falls back to `AnalysisScreen`; push `/analysis/search/5?q=&c=USD` (empty q) → falls back; push `/analysis/search/5?q=coffee&c=` (empty c) → falls back.

### Integration tests

- Not required for this feature (no cross-feature orchestration, no schema migration). The widget tests run against Drift's in-memory DB and cover the data→UI flow adequately.

---

## Decisions and Trade-offs

### Why memo-only search?

Amount and category filtering add UI complexity (filter chips, range pickers) that isn't justified for the first search feature. Memo text covers the most common use case: "find that coffee transaction." Amount/category filters can be added later as filter chips on the search bar without changing the architecture.

### Why Dart grouping instead of SQL GROUP BY?

The existing codebase groups transactions in Dart at the controller level (e.g., `HomeController` groups by date). Following this pattern keeps the DAO simple (one `watchByMemo` method) and the grouping logic testable in controller tests. For a local-first app, the data volume is small enough that in-memory grouping has no measurable performance impact.

### Why a separate detail screen instead of expanding inline?

A drill-down page gives full vertical space to the date-grouped transaction list and allows the user to use the back button to return to category results. An inline expansion (accordion-style) would make the category list scroll position confusing and limit the detail view's space.

### Why query params for the memo and currency in the route?

The memo is free-text that can contain slashes, spaces, and Unicode characters. Query parameters (`?q=memo`) are URL-encoded automatically by go_router and avoid path parsing issues. The `categoryId` is a simple int and works as a path parameter.

Currency is a query param (`?c=USD`) rather than a second path segment to keep the route shape stable: a future "all-currencies" detail variant could simply omit `c` without a different `path:`, and the route stays grep-able as `/analysis/search/:categoryId`. Currency is required *today* (the detail's overall sum must stay single-currency, since JPY 0-decimal and USD 2-decimal minor units cannot be added), but encoding it as a query param leaves room for that to change without a route migration.

### Why no result count limit?

The search is user-driven (they type a specific query) and the results are grouped by category (typically 1-5 categories match a query). There's no need for pagination at either level. If the user has thousands of transactions matching "coffee," the category grouping naturally compresses them into a handful of category cards.

### Why interactive rows on the detail screen (reversal of the original "read-only" decision)

The original design called for read-only Level 2 rows on the grounds that a search result is a *view* over transactions and that mutations from a filtered view would silently change the result set under the user. In practice, this proved to be the wrong default:

1. **Search-then-fix is the dominant flow.** Users typically search ("coffee") to *find* a row whose memo, category, or amount they want to correct. Forcing them to dismiss the search, navigate Home to the right day, and locate the row again breaks the use case the search bar is built for.
2. **The "result set silently changes" concern is illusory.** The result set is reactive — the underlying memo stream re-emits on every transaction insert / update / delete. The user can already see the row drop out of the list when they edit its memo to no longer match the query; there is no hidden state to be surprised by.
3. **The Level 1 sum is preserved.** Optimistic-hide during the 4-second undo window subtracts the row from `overallSumMinorUnits`, so the header stays consistent with the visible rows during the undo window.

The Level 1 search tile (the per-`(category, currency)` card on the search list) remains read-only — tapping it drills into the detail screen, and there is no "edit category" or "delete category" affordance from the search list. Only Level 2 transaction rows are interactive.

This decision reverses the prior `feedback_search_results_read_only` memory; future search-style features should default to "interactive rows mirror Home's UX" unless there is a slice-specific reason to make them read-only.
