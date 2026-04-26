# M5 Wave 3 — Home Slice

**Source of truth:** [`PRD.md`](../../../PRD.md) → *MVP Screens → Home Screen*, *Screen States → Home*, *Primary User Flow*, *Quick Repeat Flow*, *Layout Primitives → Home screen*, *Pagination*. Contracts inherited from [`wave-0-contracts-plan.md`](wave-0-contracts-plan.md). Duplicate-flow navigation is the producer side of Wave 0 §2.3; Transactions (Wave 2) is the consumer.

Home owns the `/home` tab: a single-day transaction list with prev/next day navigation, currency-grouped summary strip, FAB, swipe-to-delete + undo, and the duplicate entry point.

---

## 1. Goal

Replace the M4 placeholder at `lib/features/home/home_screen.dart` with the real single-day view per PRD. Day pinning, day-with-activity navigation, currency-grouped summaries, swipe actions, and the duplicate hand-off to Transactions.

**Entry criterion:** Wave 2 Transactions merged — the form at `/home/add` accepts the duplicate route extra, saves, and returns `Transaction` to the caller so Home can pin the day to the saved date.

---

## 2. Inputs

| Dependency                                  | Purpose                                                                                          | Import path                               |
|---------------------------------------------|--------------------------------------------------------------------------------------------------|-------------------------------------------|
| `transactionRepositoryProvider`             | `watchByDay`, `watchDaysWithActivity`, `delete`, plus new aggregate methods from §3              | `app/providers/repository_providers.dart` |
| `categoryRepositoryProvider`                | Resolve `transaction.categoryId` → display icon/color/name from an archived-safe category lookup | `app/providers/repository_providers.dart` |
| `accountRepositoryProvider`                 | Resolve `transaction.accountId` → account name from an archived-safe account lookup              | `app/providers/repository_providers.dart` |
| `currencyRepositoryProvider`                | Resolve `transaction.currency` → `Currency` for `money_formatter`                                | `app/providers/repository_providers.dart` |
| `money_formatter.dart`                      | Render amounts in the list and summary strip                                                     | `core/utils/money_formatter.dart`         |
| `date_helpers.dart`                         | Day boundaries, locale-aware day formatting for the nav header                                   | `core/utils/date_helpers.dart`            |
| `icon_registry.dart` / `color_palette.dart` | Render category chip per row                                                                     | `core/utils/*.dart`                       |

Home does **not** import from Transactions. Duplicate navigation uses `context.push('/home/add', extra: {'duplicateSourceId': id})` — the frozen transaction-id-only handoff honoring the Wave 2 §10 contract.

Historical rows must remain renderable after category/account archive actions. Home builds its metadata lookup from repository surfaces that still expose archived rows (`watchAll(includeArchived: true)` or equivalent archived-safe lookups), not picker-style active-only lists.

---

## 3. Repository contract additions (Wave 3's own contracts step)

Wave 0 §2.8 added `AccountRepository.watchBalanceMinorUnits`; it explicitly noted future waves would add their own repository surface extensions here, not retroactively in Wave 0.

The PRD's Home summary strip — *"`Today expense`, `Today income`, `Month net` per currency"* — cannot be derived from `watchByDay` alone (which returns a list, not aggregates) and cannot cover month boundaries. The slice adds three aggregate methods on `TransactionRepository` before the screen is implemented.

**Add to `lib/data/repositories/transaction_repository.dart`:**

```dart
/// Net per currency for transactions dated on `day` (midnight-to-midnight
/// in the device local timezone). Income contributes positively, expense
/// negatively (sign derived from `categories.type`). Emits on every insert,
/// update, or delete of a transaction on that day. Empty map if no
/// activity. Used by Home summary strip.
///
/// PRD.md → Home Screen — "Today expense, Today income, Month net per
/// currency." The split into expense/income totals is derived by the
/// controller from this map plus `watchDailyTotalsByType(day)`.
Stream<Map<String, int>> watchDailyNetByCurrency(DateTime day);

/// Split of daily totals by transaction type (expense vs income), grouped
/// by currency. Values are unsigned sums (both positive). Controller
/// combines this with `watchDailyNetByCurrency` to render today's summary.
Stream<Map<String, ({int expense, int income})>> watchDailyTotalsByType(DateTime day);

/// Net per currency for the calendar month containing `month` (timezone:
/// device local). Same sign convention as `watchDailyNetByCurrency`.
/// Emits on any transaction mutation within the month.
Stream<Map<String, int>> watchMonthNetByCurrency(DateTime month);
```

**Implementation notes:**
- Backed by Drift SQL aggregates (`SUM(amount_minor_units)` with a `CASE WHEN categories.type = 'expense' THEN -amount ELSE amount END` for net). No Dart-side aggregation — the query does the work.
- Day boundaries computed in the device's local timezone via `DateHelpers.startOfDay(...)` from `core/utils/date_helpers.dart`. `DriftTransactionRepository.watchByDay` already uses this helper (see `transaction_repository.dart` — `start = DateHelpers.startOfDay(day)`, `end = DateHelpers.startOfDay(day + 1)`); the three new methods MUST call the same helper rather than inventing a parallel implementation. Risk #2 covers the failure mode if they drift.
- Return type uses a Dart record for the expense/income split.
- No cross-currency conversion; grouping is by the transaction's `currency` column.

**Test coverage** — extends `test/unit/repositories/transaction_repository_test.dart`:
- Empty DB → each stream emits an empty map.
- Single expense in USD → `watchDailyNetByCurrency`: `{ 'USD': -amount }`; `watchDailyTotalsByType`: `{ 'USD': (expense: amount, income: 0) }`; `watchMonthNetByCurrency`: `{ 'USD': -amount }`.
- Mixed expense + income same day → correct signed net + correct split.
- Multi-currency same day → map has multiple keys, each with its own net.
- Month boundary: transaction on last day of month counted in that month; first day of next month counted in the new month.
- Timezone change (if testable): day stream re-computes against the new local timezone. If Drift's stream model doesn't react to timezone changes mid-process, document the limitation and skip.
- Streams re-emit on insert / update / delete of relevant rows.

This is the **only** repository surface change Wave 3 introduces. Slice agents must not extend the surface further during implementation; raise follow-up RFCs.

---

## 4. Deliverables

### 4.1 Files (under `lib/features/home/`)

- `home_screen.dart` — replaces the M4 placeholder.
- `home_controller.dart` — `@Riverpod(keepAlive: true) class HomeController extends _$HomeController`. Commands: `selectPrevDay`, `selectNextDay`, `selectToday`, `pinDay(DateTime)`, `deleteTransaction(int)`, `undoDelete()`.
- `home_state.dart` — Freezed sealed union (see §5).
- `widgets/day_navigation_header.dart` — prev/next chevrons + selected-day label; disabled chevrons at boundaries; selected-day label opens the manual date picker.
- `widgets/summary_strip.dart` — three-tile summary (Today expense / Today income / Month net), grouped by currency when multiple currencies are present.
- `widgets/transaction_tile.dart` — row: category icon chip, category name, amount (+/- prefix, native currency), memo preview, account name tag, time, primary tap-to-edit, and overflow actions (`Edit`, `Duplicate`, `Delete`).
- `widgets/pending_badge.dart` — placeholder badge; renders nothing when count is 0 (MVP: always 0).

### 4.2 ARB keys

Prefix: `home*`. Some keys already reserved in M4 (`homeEmptyTitle`, `homeEmptyCta`, `homeFabLabel`, `homeSummaryTodayExpense`, `homeSummaryTodayIncome`, `homeSummaryMonthNet`).

New keys (discovered during implementation): `homeDayEmptyTitle`, `homeDaySkeletonLabel`, `homeDeleteUndoSnackbar`, `homeDuplicateAction`, `homeDayLabelToday`, `homeDayLabelYesterday`, `homeDayNavPrevLabel`, `homeDayNavNextLabel`. Discovered keys carry PRD line refs; `app_en.arb`, `app_zh_TW.arb`, and `app_zh_CN.arb` are updated in the same commit while `app_zh.arb` stays fallback-only.

> **Inventory test:** every new key MUST also be added to the `_expectedEnKeys` set in `test/unit/l10n/arb_audit_test.dart` in the same commit. That test enforces the plan-vs-ARB contract (§5 inventory) and fails loudly when a key lands in `app_en.arb` without a matching entry in the audit. Wave 2 hit this exact failure when its `tx*` keys were added without updating the audit; the same trap applies here.

### 4.3 Tests

- `test/unit/controllers/home_controller_test.dart` — day traversal via `watchDaysWithActivity` (prev/next step-over empty days); `selectToday` pins to today; `deleteTransaction` schedules a timer and surfaces an undo window; `undoDelete` cancels the timer without touching the repository; timer expiry triggers `repo.delete`.
- `test/widget/features/home/home_screen_test.dart` — first-run empty state renders `homeEmptyTitle` + `homeEmptyCta` CTA; per-day empty state after navigating to a gap day; summary strip renders chips per currency; row tap opens `/home/edit/:id`; overflow duplicate navigates with the correct route extra; overflow delete and swipe-delete both surface the same undo snackbar; archived category/account metadata still render in historical rows; `>=600dp` renders the tablet two-pane layout.
- `test/widget/features/home/summary_strip_test.dart` — single-currency case, multi-currency case, all-zero case.
- `test/widget/features/home/day_navigation_header_test.dart` — prev disabled at oldest day, next disabled when there is no newer activity day, both active in between, selected-day label opens the manual date picker.

---

## 5. State machine

```dart
@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.loading() = _Loading;
  const factory HomeState.empty({
    required DateTime selectedDay,
    required int pendingBadgeCount,
  }) = _Empty;
  const factory HomeState.data({
    required DateTime selectedDay,
    required List<Transaction> transactionsForDay,
    required Map<String, ({int expense, int income})> todayTotalsByCurrency,
    required Map<String, int> monthNetByCurrency,
    required DateTime? prevDayWithActivity, // null → prev disabled
    required DateTime? nextDayWithActivity, // null → next disabled
    required int pendingBadgeCount,         // always 0 in MVP (Wave 0 §2.3)
    required PendingDelete? pendingDelete,  // set during the undo window; null otherwise
  }) = _Data;
  const factory HomeState.error(Object error, StackTrace stack) = _Error;
}

class PendingDelete {
  final Transaction transaction;
  final DateTime scheduledFor;
}
```

- `empty` is the first-run / no-history state. The controller emits it when `watchDaysWithActivity(limit: 1)` returns no rows; the widget renders the CTA from this variant instead of overloading `data`.
- `data` covers both populated days and manual gap-day empties (`transactionsForDay.isEmpty`).
- `transactionsForDay` comes from `watchByDay(selectedDay)`; the controller does **not** filter in Dart.

---

## 6. Day navigation mechanics

PRD: *"Home shows one day at a time … prev/next controls advance by one day-with-activity at a time."*

Data source: `watchDaysWithActivity(...)` returns a list of dates sorted descending.

Controller derivation:
- `prevDayWithActivity = daysWithActivity.firstWhereOrNull((d) => d.isBefore(selectedDay))`
- `nextDayWithActivity = daysWithActivity.lastWhereOrNull((d) => d.isAfter(selectedDay))`

Edge cases:
- `selectedDay == today` and no transactions today but there is history: if there is no newer activity day, next disabled; otherwise next points at the nearest newer activity day. Prev points at the most recent older activity day when one exists.
- `selectedDay == today` and no history at all: both disabled; emit `HomeState.empty(selectedDay: today, pendingBadgeCount: 0)`.
- User taps `selectedDay` label → opens `showDatePicker` with `firstDate` = oldest day with activity (or today when no history) and a `lastDate` that extends beyond today so the PRD's manual future-gap-day path remains reachable. Choosing a future day with no activity renders the per-day empty state in `HomeState.data(...)`.

`selectToday()` command always pins to today even when today has no activity. If history exists, this renders the per-day empty state; if no history exists, it emits `HomeState.empty(...)`.

---

## 7. Summary strip layout

Per PRD: *"Compact summary strip grouped by currency in MVP (`Today expense`, `Today income`, `Month net` per currency)."*

- Horizontal `Wrap` (not a `Row`) so multi-currency doesn't overflow.
- Each chip: `<label>` / `<amount in currency>` using `money_formatter`.
- Empty-state (all three values are 0 across all currencies): strip shows `—` placeholders, not hidden.
- Multi-currency: three chips per currency, grouped visually (e.g., separator between currency groups).

The strip does **not** show an auto-converted total. That is explicitly Phase 2 per PRD → *MVP Currency Policy*.

---

## 8. Delete + undo mechanics

Swipe-to-delete on a transaction tile (via `flutter_slidable`) is the primary destructive gesture. The same delete path is also reachable from the row overflow menu so delete is not gesture-only.

1. Widget calls `controller.deleteTransaction(id)`.
2. Controller snapshots the transaction, sets `pendingDelete`, starts a 4-second `Timer`. The widget subscribing to state observes the pending delete and hides the row from the rendered list (visual deletion). The DB row is **not** touched yet.
3. Controller shows a SnackBar via a callback the widget registers, with action `commonUndo`.
4. On undo tap: controller cancels the timer, clears `pendingDelete`. The row reappears (no DB change happened).
5. On timer expiry: controller calls `transactionRepositoryProvider.delete(id)`, clears `pendingDelete`. The `watchByDay` stream re-emits without the row (actual deletion).

Why timer-based (not repo-level soft delete): the repository doesn't expose a soft-delete method, and adding one is a larger contract change than warranted for undo. This approach keeps the repo contract clean.

Edge cases:
- User swipes-deletes a second row while the first is still pending: queue, or immediately commit the first and start a new timer for the second. Simpler: the controller holds a **single** `pendingDelete`; swiping again commits the prior and starts fresh. Document this in the test.
- App backgrounded mid-timer: the delete may not execute if the app is killed. Accept this for MVP — the transaction reappears on next launch via the stream. Document in release notes.
- Navigate away from Home mid-timer: `HomeController` stays alive for the undo window (`@Riverpod(keepAlive: true)`), so the timer still fires and commits the delete unless the user already tapped undo.

---

## 9. Edit + duplicate entry points (Wave 0 §2.3 producer side)

Each `TransactionTile` exposes a Duplicate action via:
- Primary tap → `final savedTx = await context.push<Transaction>('/home/edit/${transaction.id}')`. If `savedTx != null`, Home calls `pinDay(savedTx.date)` so edit-save follows the same return-to-day contract as add/duplicate.
- Overflow menu → `Edit`, `Duplicate`, `Delete`. Pick overflow for MVP consistency with the Accounts/Categories slices' overflow-first pattern; swipe-to-duplicate is future work.

On tap: `context.push('/home/add', extra: {'duplicateSourceId': transaction.id})`. Navigation only; Transactions slice reads the extra and hydrates the form (Wave 2 §10).

Home does not retain any duplicate-related state. When the form returns (via `pop(savedTx)`), Home uses the returned `Transaction.date` to pin the day via `pinDay(savedTx.date)`.

---

## 10. FAB

- `FloatingActionButton.extended` with `homeFabLabel` semantics ("Add transaction").
- Tap → `final savedTx = await context.push<Transaction>('/home/add')` (no extra — Add mode).
- If `savedTx != null`, call `pinDay(savedTx.date)`, then rely on `watchByDay` + `watchDailyTotalsByType` streams to surface the new row. No manual list mutation.
- FAB, day-nav chevrons, duplicate action, delete action, and undo snackbar action all carry explicit `Semantics` labels per PRD accessibility requirements.

---

## 11. Layout (per PRD → Layout Primitives → Home)

```text
Scaffold
  └─ CustomScrollView
      ├─ SliverAppBar (or no app bar; the day-nav header replaces it)
      ├─ SliverToBoxAdapter — summary strip (currency-grouped)
      ├─ SliverToBoxAdapter — day navigation header (prev ◀ {selectedDate} ▶ next)
      ├─ SliverList — TransactionTile per transaction (reverse-chronological within the day)
      └─ SliverPadding — FAB clearance
  └─ floatingActionButton: FloatingActionButton.extended(...)
```

- Never nest `ListView` in `Column` (PRD Layout Primitives — non-negotiable).
- 2× text scale: summary strip wraps (already `Wrap`); day nav header clamps at 1.5× (fixed-height region); transaction tiles reflow.

Adaptive layout:
- `<600dp`: use the single-pane sliver structure above.
- `>=600dp`: switch to the PRD's two-pane Home layout. The left pane is the activity-day chooser / navigation surface driven by `watchDaysWithActivity(...)`; the right pane reuses the selected-day detail body (summary strip + selected day's transactions or per-day empty state) driven by the same `selectedDay` source of truth.
- First-run empty state spans the content region instead of rendering a blank split pane.
- Do **not** ship the phone single-pane Home unchanged on `>=600dp`.

> **Out of scope: form's own adaptive container.** The `/home/add` and `/home/edit/:id` routes already adapt at 600dp via `_AdaptiveTransactionFormRoute` in `lib/app/router.dart` (added during Wave 2): fullscreen below 600dp, `Dialog(maxWidth: 560)` at and above. Wave 3's adaptive concern is **only** Home's own screen. Do not re-implement the form adaptation, and do not edit `router.dart`.

---

## 12. Cross-slice contract adherence (Wave 0)

- §2.3 — Home is the producer of the duplicate flow: swipe/overflow + route navigation. Transactions (Wave 2) is the consumer.
- §2.3 — Pending badge count = 0 in MVP; the `pending_badge.dart` widget renders nothing when count is 0. Do not wire a real stream in MVP.
- §2.3 — Home's delete uses a SnackBar with `commonUndo`; no shared row/undo widget is extracted in MVP.
- §2.4 — Wave 3's repository additions (§3) are the only change to repository surface. No other data-layer work.
- §2.4 — Do **not** edit `router.dart`. `/home/add` and `/home/edit/:id` are already wired with adaptive 600dp presentation; Home only navigates to them via `context.push`. Mirrors the equivalent Wave 2 §11 stance now that the router is fully wired.
- §2.5 — All widgets under `lib/features/home/widgets/`. No cross-slice imports.

---

## 13. Out of scope (defer)

- **Charts** (pie/bar) — Phase 2.
- **Search** — Phase 2.
- **Pending transactions** (review/approve) — Phase 2.
- **Auto-converted totals** in default currency — Phase 2 (PRD *MVP Currency Policy*).
- **Pagination beyond 10 000 transactions** — Phase 2 (`watchPage` cursor API).
- **Swipe-to-duplicate** — deferred; overflow is the sole duplicate affordance in MVP.
- **Calendar heatmap / month grid** — not in MVP.

---

## 14. Exit criteria

- Wave 3 repository additions from §3 are merged (either in the slice PR or a Platform-owned prior PR — slice PR is acceptable since Wave 3 is a single slice). Tests in `test/unit/repositories/transaction_repository_test.dart` cover the three new methods per §3.
- `home_screen.dart` renders: first-run empty, per-day list with summary strip, per-day empty (gap day), error state.
- Prev/next navigation traverses days-with-activity correctly; both chevrons disable at boundaries; `selectToday` snaps to today.
- Swipe-delete surfaces undo snackbar; undo within 4 s restores the row; past 4 s the delete commits.
- Duplicate action navigates to `/home/add` with `duplicateSourceId` extra; Wave 2 form prefills correctly.
- Row tap navigates to `/home/edit/:id`; save returns a persisted `Transaction` and Home re-pins to `savedTx.date`.
- Save from the form returns to Home and pins the day to `savedTx.date` with the new row visible.
- Historical rows still render archived category/account metadata.
- `>=600dp` uses the PRD two-pane Home layout instead of the phone single-pane scroll view.
- 2× text scale passes on the screen.
- `flutter analyze` clean; `flutter test` green.

---

## 15. Sequencing

Single agent, single PR. Entry: Wave 2 merged.

1. Implement §3 repository additions in `transaction_repository.dart` + `DriftTransactionRepository`. Extend `test/unit/repositories/transaction_repository_test.dart` with the cases from §3. Get repo tests green in isolation before touching the UI.
2. Implement `home_state.dart` + `home_controller.dart` — consume the new aggregate streams; derive `empty` vs `data`, `prevDayWithActivity`, and `nextDayWithActivity`.
3. Implement `widgets/summary_strip.dart` + `widgets/day_navigation_header.dart` + `widgets/transaction_tile.dart` + `widgets/pending_badge.dart`.
4. Assemble `home_screen.dart`, wiring FAB + row tap edit + overflow actions + swipe delete.
5. Implement delete + undo timer logic in the controller; SnackBar wiring in the screen via a callback pattern.
6. Add ARB keys (§4.2) across `app_en.arb`, `app_zh_TW.arb`, and `app_zh_CN.arb`.
7. Write controller + widget tests.
8. Manually verify the save-return-pin-day round-trip works end-to-end with Wave 2's form on device / simulator.
9. Run `dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test`.
10. Open PR titled `feat(m5): home slice`.

---

## 16. Risks

1. **Aggregate query performance.** `SUM(...)` over thousands of rows inside a reactive stream might flicker on large DBs. MVP pagination cap is 10 000 rows; verify query completes in <50 ms on that size. Benchmark in repository tests.
2. **Timezone drift.** `watchByDay`, `watchDailyNetByCurrency`, `watchMonthNetByCurrency` must all use the same day-boundary logic. Extract a single helper in `date_helpers.dart` (or reuse existing) and have all three methods call it.
3. **Delete-undo timer across controller rebuilds.** `HomeController` is `@Riverpod(keepAlive: true)` so the pending-delete timer survives trivial rebuilds and off-screen navigation during the undo window.
4. **Second swipe-delete mid-undo.** Committing the first delete when the second arrives is correct MVP behavior — a queue-based undo is overkill. Widget test: rapid two-row swipe commits first, starts undo for second.
5. **Currency pivot in summary strip.** If the user's only account is USD and they later add a JPY account, the strip silently gains a second set of chips. Test with multi-currency fixture.
6. **Empty `prevDayWithActivity` when on oldest day.** Disable chevron, don't throw. Covered in day-nav widget test.
7. **Summary strip flickers while streams race.** The screen needs `todayTotalsByCurrency`, `monthNetByCurrency`, `transactionsForDay`, and `daysWithActivity` simultaneously. Use a single `AsyncValue.unwrapPrevious()`-style aggregation in the controller so the screen sees a coherent snapshot, not four independent `AsyncValue`s.
8. **Integration with Wave 2's save-return contract.** If Wave 2 lands without returning `Transaction` from `context.pop`, Home cannot pin the day. Smoke-test manually; if broken, file a Wave 2 follow-up rather than working around it in Home.
