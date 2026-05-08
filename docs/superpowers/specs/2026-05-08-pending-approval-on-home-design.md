# Pending Approval on Home — Design Spec

## Overview

Recurring rules generate rows in `pending_transactions` on cold start. Today, those rows have nowhere to go in the UI — Wave 3 Home shipped with `pendingBadgeCount` hardcoded to `0` and no surface for review. This spec adds an inline approval surface on Home, completing the recurring-transactions feature loop.

**Goal:** A user with a due recurring rule sees a single tap on Home to approve it. The approved row immediately moves into today's transaction list. Skipping a row uses the same swipe-with-undo gesture vocabulary that already exists for transaction delete.

**Acceptance criterion:** A pending row generated for `today` appears in a sticky section above today's transaction list. Tapping its circle Approve button animates the circle grey → green over 200 ms, then atomically inserts a `transactions` row and deletes the pending row. The section auto-hides when no pending rows exist.

**Scope decisions (from brainstorming):**
- Pending-row approval **on Home only** — no separate Pending Transactions screen.
- One-tap approve using the rule's snapshot data verbatim — no confirmation dialog, no per-row edit.
- Pending rows render in a **sticky section** above today's list, regardless of `selectedDay`.
- Reject (Skip) deletes the pending row only; parent rule untouched, next occurrence still generates on schedule.
- Visual: yellow-tinted tile with a 36-px grey circle Approve button; swipe-left reveals red Skip action.
- Tapping the row body is a no-op.
- Approve failure shows `errorSnackbarGeneric`; row stays in place.
- State machine lives in a new `PendingController` independent of `HomeController` — no shared providers.

The trade-offs behind these choices are spelled out in the **Decisions and Trade-offs** section at the bottom.

---

## Prerequisites

The data layer this spec depends on **already exists** (shipped with the recurring transactions slice on 2026-05-08):

- `pending_transactions` table (Drift v4 migration).
- `PendingTransactionRepository` with `existsForRuleAndDate`, `insert`, `countByRecurringRule`.
- `RecurringGenerationUseCase` writes pending rows on cold start.
- The `pending_badge.dart` widget renders a count chip when `count > 0`.

This spec adds three new methods to `PendingTransactionRepository`, a new feature slice under `lib/features/home/`, and one ARB key set. No DB migration is required.

The recurring-rules feature deliberately deferred this UI to Wave 3 (see [recurring transactions plan](../plans/2026-05-07-recurring-transactions.md), "Wave-3 coordination" header). This spec is the catch-up — Wave 3 itself shipped first without pending integration.

---

## Architecture

`PendingController` and `HomeController` share **no provider dependencies**. Both read the same `AppDatabase` through independent repository providers; Drift's stream invalidation is what keeps them coherent. The pending section is a sliver that mounts above the existing transaction list — it does not extend `HomeState`.

| Component                      | Layer           | Responsibility                                                                                              |
|--------------------------------|-----------------|-------------------------------------------------------------------------------------------------------------|
| `PendingTransactionRepository` | Data            | SSOT for `pending_transactions`. Adds `watchAll`, `approve`, `reject` (this spec). |
| `PendingController`            | UI / state      | Composes `watchAll()` into `PendingState`. Owns the skip-with-undo timer and effect listener.               |
| `PendingState`                 | UI / state      | Freezed sealed union: `loading \| empty \| data \| error`.                                                    |
| `PendingSection`               | UI / widget     | Sticky `SliverToBoxAdapter` mounted on `HomeScreen`. Watches `pendingControllerProvider`.                   |
| `PendingTile`                  | UI / widget     | Single-row tile with circle Approve button + swipe-left Skip action.                                        |
| `_ApproveCircleButton`         | UI / widget     | StatefulWidget that owns the 200 ms grey-to-green animation and debounces taps.                             |

**Rule of file location:** the controller and widgets live under `lib/features/home/` because their only consumer is `HomeScreen`. If a future Phase 2 plan adds a dedicated Pending Transactions screen, the controller can move to `lib/features/pending_transactions/` at that time.

`HomeController` and `HomeState` are unchanged by this spec.

---

## Data Model — repository surface additions

`PendingTransactionRepository` (`lib/data/repositories/pending_transaction_repository.dart`) gains three methods:

```dart
abstract class PendingTransactionRepository {
  // Existing — unchanged
  Future<bool> existsForRuleAndDate(int ruleId, DateTime date);
  Future<int> insert({...});
  Future<int> countByRecurringRule(int ruleId);

  // New
  Stream<List<PendingTransaction>> watchAll();

  /// Approve: insert into `transactions` and delete the pending row,
  /// atomically. The rule's `next_due_date` is NOT touched (it was already
  /// advanced when the pending row was generated).
  ///
  /// Throws [PendingTransactionRepositoryException] when:
  ///   - The pending row id does not exist.
  ///   - The referenced account is archived or missing.
  ///   - The referenced category is archived or missing.
  ///   - The referenced currency code is unregistered.
  Future<Transaction> approve(int pendingId);

  /// Reject: delete the pending row. Idempotent — calling on a missing id
  /// returns without throwing. Parent rule unaffected.
  Future<void> reject(int pendingId);
}
```

### Implementation notes

- `approve` opens a single `db.transaction(...)`, resolves the pending row, builds a `Transaction` domain value, calls `TransactionRepository.save(...)` for the write, then deletes the pending row. This mirrors the composition exception that `ShoppingListRepository.convertToTransaction` documents — both pre-existing and accepted.
- `watchAll()` returns rows ordered by `date DESC, id DESC`. No `source` filter — recurring is the only producer today; future blockchain rows can co-exist without UI changes here.
- `reject` is a single delete; it does not need to be transactional. Idempotency is "0 rows affected returns normally."

### Data model — `PendingTransaction` (existing)

The model already exists from the recurring slice. No changes:

```dart
@freezed
class PendingTransaction with _$PendingTransaction {
  const factory PendingTransaction({
    required int id,
    required String source,           // 'recurring' (today) | 'blockchain' (future)
    required int amountMinorUnits,
    required Currency currency,
    int? categoryId,
    required int accountId,
    String? memo,
    required DateTime date,
    required DateTime fetchedAt,
    int? recurringRuleId,
  }) = _PendingTransaction;
}
```

---

## State Machine

```dart
// lib/features/home/pending_state.dart

/// A pending row currently inside the 4-second skip-undo window. Held
/// in-memory by the controller, NOT in the DB — the row only gets
/// deleted from `pending_transactions` when the timer expires.
///
/// Named `…Skip…` (not `…Delete…`) to avoid collision with the feature's
/// own "pending" terminology.
class PendingSkipScheduled {
  const PendingSkipScheduled({required this.pendingId, required this.scheduledFor});
  final int pendingId;
  final DateTime scheduledFor;
}

@freezed
sealed class PendingState with _$PendingState {
  /// Pre-first emission from `watchAll()`.
  const factory PendingState.loading() = PendingLoading;

  /// No un-approved pending rows. The screen renders nothing — no
  /// "No pending items" placeholder. Existing approved-transaction list
  /// continues uninterrupted.
  const factory PendingState.empty() = PendingEmpty;

  const factory PendingState.data({
    required List<PendingTransaction> items,
    required PendingSkipScheduled? skipScheduled,
  }) = PendingData;

  const factory PendingState.error(Object error, StackTrace stack) = PendingError;
}
```

`PendingController` mirrors `ShoppingListController` and `RecurringRulesController`:

```dart
@Riverpod(dependencies: [pendingTransactionRepository])
class PendingController extends _$PendingController {
  PendingSkipScheduled? _skipScheduled;
  Timer? _undoTimer;
  _Composer? _composer;
  PendingEffectListener? _effectListener;

  @override
  Stream<PendingState> build() { ... }

  Future<void> approve(int pendingId);  // calls repo.approve, fires effect on failure
  Future<void> skip(int pendingId);     // hides row, starts 4s timer
  Future<void> undoSkip();              // cancels timer, restores row
  void setEffectListener(PendingEffectListener? listener);
}
```

### Effects

```dart
sealed class PendingEffect { const PendingEffect(); }

final class PendingApproveFailedEffect extends PendingEffect {
  const PendingApproveFailedEffect(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

final class PendingSkipFailedEffect extends PendingEffect {
  const PendingSkipFailedEffect(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}
```

Two distinct effect types so a future Wave can differentiate the snackbar copy without a controller refactor. v1 surfaces the same `errorSnackbarGeneric` for both.

---

## UI Design

### Sliver composition on `HomeScreen`

```text
CustomScrollView
  ├─ SliverToBoxAdapter — summary strip                 (existing, unchanged)
  ├─ SliverToBoxAdapter — day navigation header         (existing, unchanged)
  ├─ SliverToBoxAdapter — PendingSection                ← new
  ├─ SliverList         — TransactionTile per row       (existing, unchanged)
  └─ SliverPadding      — FAB clearance                 (existing, unchanged)
```

**Why this position:** the summary strip stays anchored at top as the visual "what happened today" lens. Pending sits between the day-nav and the transaction list, reading as "stuff waiting on you" before the day's detail. Since the section auto-hides on empty, users without rules see no Home layout change.

### `PendingSection` — ConsumerWidget

- Watches `pendingControllerProvider`.
- Registers a `PendingEffectListener` on first build that surfaces `Approve`/`Skip` failures via `ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)))`. The listener pattern matches `ShoppingListScreen` and `RecurringRulesScreen` (cached notifier in `_bindController`, cleared in `dispose`).
- Filters `items` by `skipScheduled?.pendingId` so the visually-skipped row hides immediately without round-tripping through the repository.
- States:
  - `PendingLoading` → `SizedBox.shrink()` (no skeleton; the stream emits within ~1 frame).
  - `PendingEmpty` → `SizedBox.shrink()` (section disappears entirely; per *Empty state* below).
  - `PendingData(items: [], skipScheduled: <set>)` → `SizedBox.shrink()` for the visible content but the controller stays alive so the undo SnackBar's action button remains wired.
  - `PendingData(items: [...], ...)` → header + `Column` of `PendingTile`s (not a nested `ListView` — see Layout Primitives in PRD).
  - `PendingError` → small Material banner inline with `homePendingLoadError`; the rest of Home keeps working.

### Section header

```text
PENDING · 2 items
─────────────────
[ tile ]
[ tile ]
```

Reuses the existing `PendingBadge` widget for the count chip (currently dormant). The badge moves from its old day-nav-header placeholder location into this section header. The hardcoded `pendingBadgeCount: 0` reference in `HomeState.data` is removed in this slice.

### `PendingTile` — StatefulWidget

```text
┌──────────────────────────────────────────────────┐
│ [icon]  Netflix             $15.99   [grey ✓]   │  ← yellow tint, 3-px tertiary left border
│         Subscriptions · Cash · May 8              │
└──────────────────────────────────────────────────┘
       ↔ swipe-left → red [Skip] action pane
```

Visual:
- Container: `Material(color: theme.colorScheme.tertiaryContainer)` with a 3-px solid `theme.colorScheme.tertiary` left border. Same color family that `pending_badge.dart` already uses; no new theme tokens.
- Leading: 24×24 category icon resolved via `iconForKey(categoryRow.icon)` + `colorForIndex(categoryRow.color)` when `categoryId != null`. Falls back to `Icons.schedule` when `categoryId` is null (blockchain-source rows in the future).
- Title: the rule snapshot's `memo` (which doubles as the rule name per the recurring-rule design).
- Subtitle: `<categoryName> · <accountName> · <localized date>`. Reuses `categoryDisplayName` from the categories slice and `intl.DateFormat.yMMMd()` for the date.
- Trailing: amount via `money_formatter` + `_ApproveCircleButton` to its right.
- Body tap: no-op. The Approve button has its own `onPressed`.
- Swipe-left: `flutter_slidable` `endActionPane` with one `SlidableAction` labeled `homePendingSkip`. Background `theme.colorScheme.error`; foreground `theme.colorScheme.onError`. Same gesture vocabulary as transaction delete on the existing list.

### `_ApproveCircleButton` — StatefulWidget

Default state:
- 36 × 36 circle. Background `theme.colorScheme.surfaceVariant`; icon `Icons.check` rendered in `theme.colorScheme.onSurfaceVariant`.
- Wrapped in 4-px padding inside a `GestureDetector`/`InkWell` to give a 44 × 44 hit-target.

Tap interaction:
1. Tap arrives. If `_approving == true`, ignore (debounce).
2. Set `_approving = true`. `AnimationController` (200 ms) drives:
   - Background lerp: `surfaceVariant` → `tertiary`.
   - Scale: `1.0 → 1.06` via `ScaleTransition`.
3. On `AnimationStatus.completed`, await `controller.approve(pendingId)`.
4. **Success:** the pending stream re-emits without the row. The `SliverList` removes the tile via `AnimatedSize` (150 ms collapse). Total perceived sequence: ~350 ms tap → green → slide-out.
5. **Failure:** the controller fires `PendingApproveFailedEffect`. The animation reverses (200 ms green → grey), `_approving` clears, the row stays in place. `errorSnackbarGeneric` shows.

Accessibility:
- `Semantics(button: true, label: l10n.homePendingApprove)` wraps the circle. Screen-reader users invoke approve without needing the swipe gesture for skip; behavior is identical to the visual flow.
- Skip path: `flutter_slidable` already exposes the action via accessibility actions.

### Empty state

When `items` is empty and `skipScheduled` is null, the section renders as `SizedBox.shrink()` — no header, no banner, no padding. Users without recurring rules see Home exactly as it shipped.

When `items` is empty but `skipScheduled` is set (the user just swiped-skipped the only pending row), the section renders nothing visually; the SnackBar is the user's affordance to undo. Once the timer expires or the user taps undo, state collapses normally.

---

## Approve / Skip Mechanics

### Approve flow (one-tap)

```
[user taps Approve circle]
       │
       ▼
_ApproveCircleButton runs 200ms grey→green animation
       │
       ▼
PendingController.approve(pendingId)
       │
       ▼
PendingTransactionRepository.approve(pendingId)   ← single db.transaction
   ├─ insert into transactions    (TransactionRepository.save)
   └─ delete from pending_transactions
       │
       ▼
Two streams re-emit independently:
   1. PendingController's watchAll        → row gone from PendingSection
   2. HomeController's watchByDay         → row appears in today's list
   3. HomeController's watchDailyTotalsByType → summary strip updates
       │
       ▼
Snackbar: homePendingApprovedSnack ("Approved — Netflix")
```

No optimistic UI. Drift's reactive streams propagate the change within a frame; the AnimatedSize collapse handles the row exit.

### Skip-with-undo flow (mirrors transaction delete-undo)

```
[user swipes left]
       │
       ▼
PendingController.skip(pendingId)
       │
       ▼
1. _skipScheduled = PendingSkipScheduled(pendingId, scheduledFor: now + 4s)
2. _composer.notifyChanged()  → emits PendingData with items filtered
3. Effect: SnackBar(
       content: Text(homePendingSkippedSnack),
       duration: kUndoWindow,
       action: SnackBarAction(label: commonUndo, onPressed: undoSkip),
     )
4. _undoTimer = Timer(kUndoWindow, () => _commitSkip(pendingId))
       │
   ┌───┴───┐
   ▼       ▼
[undo tap]   [timer fires]
   │         │
   ▼         ▼
cancel       repo.reject(pendingId)
timer;       → pending row deleted from DB
clear        → stream re-emits without it
state;       (the visual already matches)
row
returns
```

**Edge cases (mirroring the delete-undo behavior in `RecurringRulesController.deleteRule` and `ShoppingListController.deleteItem`):**

- **Second skip during a pending undo:** the controller commits the prior swipe immediately via `_commitSkip(prior.pendingId)`, then starts a fresh undo window for the new id. Users can blast through several pending rows; only the last one has an outstanding undo.
- **Reject failure during commit (DB locked, etc.):** clears `_skipScheduled`, calls `_composer.notifyChanged()` so the row reappears, fires `PendingSkipFailedEffect` → `errorSnackbarGeneric`.
- **Second skip while the undo timer is firing:** the timer's callback already nulls `_skipScheduled` before the await; the new skip starts cleanly.

### Approve failure handling

The pending row's snapshot can outlive its references. Between rule creation and the user's tap, the linked account or category may have been archived from the management screens. `repo.approve` throws `PendingTransactionRepositoryException` for any of:

- Pending row not found (race: user double-tapped while the row was deleting).
- Account archived or missing.
- Category archived or missing.
- Currency code unregistered.

The controller catches via `try / catch (error, stackTrace)`, fires `PendingApproveFailedEffect(error, stackTrace)`, and lets the row stay. The screen surfaces `errorSnackbarGeneric` ("Something went wrong. Try again."). The user fixes the underlying rule via `/settings/recurring/:id` (already shipped) — there is no in-Home rule editor.

This matches the existing transaction-delete failure path; same shape, no special-casing.

---

## State Coherence with `HomeController`

`PendingController` and `HomeController` share **no provider dependencies**. Both read `AppDatabase` through independent repository providers. Drift's stream invalidation handles cross-controller coherence: when `approve` writes both tables in one transaction, both controllers' streams re-emit on their own.

This matters for testability. Controller tests for `PendingController` mock only `PendingTransactionRepository`. Widget tests for `PendingSection` don't mount the rest of Home.

The PRD's *Wave 0 §2.4* "Wave-3 repository additions are the only change to repository surface" rule is preserved: this spec extends `PendingTransactionRepository` (which Wave 3 itself didn't extend) and does not modify `TransactionRepository`'s contract — `approve` calls the existing `save(...)`.

---

## Bootstrap Interaction

`bootstrap.dart` was refactored on 2026-05-08 to schedule `runRecurringGenerationFn(db)` from `App.onFirstFrame` instead of inline within `bootstrapFor`. This means:

- The recurring generation pass runs **after** the first frame paints.
- `lastGenerationResultProvider` is overridden with `const RecurringGenerationResult(outcomes: [])` for the duration of startup. No banner could surface "rules failed during generation" even if we wanted one.
- Failures inside `runRecurringGenerationFn` are caught and swallowed in the `App.onFirstFrame` body ("Generation failures must not crash or block startup").

For this spec, the implications are:

1. `PendingController` MUST be stream-driven. It cannot snapshot a one-time read at build — pending rows arrive after first frame.
2. There is **no Home-level surface** for cap-hit (`anyCapped`) or generation-failure (`anyFailed`) state. Per-rule state still surfaces on the rule tile (`RecurringRule.lastError`) at `/settings/recurring`.
3. A user who has a generation failure during cold start sees no notification. They discover it via the rule's error icon at the next visit to the management screen. This is a documented gap; surfacing cold-start failures on Home is left to a future Phase 2 plan.

---

## l10n

Six new keys land in `app_en.arb`, `app_zh_TW.arb`, `app_zh_CN.arb`, AND `_expectedEnKeys` in `test/unit/l10n/arb_audit_test.dart` in the same commit.

| Key                          | EN value                                  | Notes                                                 |
|------------------------------|-------------------------------------------|-------------------------------------------------------|
| `homePendingSectionTitle`    | "Pending"                                 | Section header label                                  |
| `homePendingApprove`         | "Approve"                                 | Semantics label on the circle button (no visible text)|
| `homePendingSkip`            | "Skip"                                    | Swipe action label                                    |
| `homePendingApprovedSnack`   | "Approved — {ruleName}"                   | Success snackbar; placeholder `ruleName` (String)     |
| `homePendingSkippedSnack`    | "Skipped — undo?"                         | Skip-undo snackbar                                    |
| `homePendingLoadError`       | "Couldn't load pending items."            | Error banner copy                                     |

ARB audit is the canonical "did we forget the audit allowlist?" trap — Wave 2's `tx*` keys and the recurring `recurring*` keys both hit it during their slices. Adding the keys without updating `_expectedEnKeys` fails CI loudly.

---

## Testing

### Repository tests

Extend `test/unit/repositories/pending_transaction_repository_test.dart`:

- `watchAll`: empty DB → empty list; rows emitted in `date DESC, id DESC` order; stream re-emits on every `approve` / `reject`.
- `approve` happy path: builds a `Transaction` with snapshot's amount, currency, account, category, memo, date — verbatim. Inserts one row in `transactions`, deletes one row from `pending_transactions`. Idempotent in the sense that calling on an id that's already gone throws (no silent no-op; the user already saw the visual change).
- `approve` failure paths: missing pending row, archived account, archived category, unregistered currency. After each thrown approve, both tables are unchanged (atomicity check).
- `approve` does NOT modify the parent recurring rule's `next_due_date`.
- `reject` happy path: deletes one row.
- `reject` idempotency: calling on a missing id returns normally and writes nothing.
- `reject` does NOT modify the parent recurring rule.

### Controller tests

New file `test/unit/controllers/pending_controller_test.dart`. Mirrors the `recurring_rules_controller_test.dart` shape — mocked repository, broadcast `StreamController`, `fake_async` for timers.

| ID    | Behavior                                                                              |
|-------|---------------------------------------------------------------------------------------|
| PC01  | loading → data when stream emits items                                                |
| PC02  | loading → empty when stream emits empty list                                          |
| PC03  | stream error becomes `PendingError`                                                   |
| PC04  | `approve` calls `repo.approve(id)`; no effect fires on success                        |
| PC05  | `approve` failure fires `PendingApproveFailedEffect`; row stays in `PendingData.items`|
| PC06  | `skip` hides row immediately and starts undo window                                   |
| PC07  | `undoSkip` cancels timer; `repo.reject` never called                                  |
| PC08  | timer expiry calls `repo.reject(id)` (uses `fakeAsync.elapse(kUndoWindow + 1s)`)      |
| PC09  | failed `reject` fires `PendingSkipFailedEffect` and restores row                      |
| PC10  | second `skip` during pending undo commits the prior, opens new window                 |

### Widget tests

New file `test/widget/features/home/pending_section_test.dart` (PendingSection-level) and `test/widget/features/home/pending_tile_test.dart` (PendingTile + ApproveCircleButton). Use the `_FakeController` pattern from `recurring_rules_screen_test.dart`.

Section tests:

| ID    | Behavior                                                                     |
|-------|------------------------------------------------------------------------------|
| PS01  | `PendingLoading` → `SizedBox.shrink` (no skeleton flicker)                   |
| PS02  | `PendingEmpty` → `SizedBox.shrink` (section disappears entirely)             |
| PS03  | `PendingData` with N items → header "Pending · N items" + N tiles            |
| PS04  | tap on row body does nothing (no router push observed) — guards No-op decision |
| PS05  | error variant renders the inline banner with `homePendingLoadError`          |

Tile / button tests:

| ID    | Behavior                                                                                                         |
|-------|------------------------------------------------------------------------------------------------------------------|
| PT01  | default circle is grey with white check icon                                                                     |
| PT02  | tapping the circle advances the animation; `AnimationStatus.completed` triggers `controller.approve(id)` once    |
| PT03  | rapid double-taps invoke approve only once (debounce via `_approving` flag)                                      |
| PT04  | failed approve animates the circle back to grey and re-enables the tap                                           |
| PT05  | swipe-left reveals Skip action; tapping it calls `controller.skip(id)`                                           |
| PT06  | localized subtitle renders `"<categoryName> · <accountName> · <date>"`                                           |
| PT07  | 2× text scale doesn't overflow the trailing slot — amount and circle button fit                                  |

### Integration test

New file `test/integration/pending_approval_flow_test.dart`. End-to-end against an in-memory `AppDatabase`.

1. Seed → create a recurring rule → run `RecurringGenerationUseCase.execute(clock: today)` to populate one pending row.
2. Pump the full app via `bootstrapFor(...)` (same harness `bootstrap_to_home_test.dart` uses).
3. Land on Home → assert `PendingSection` renders the row.
4. Tap the Approve circle → assert the row leaves the section AND a `TransactionTile` appears in today's list with the right amount/category/account.
5. Swipe-left → assert SnackBar appears, tap **Undo** within 4 s → assert the row reappears.
6. Swipe-left again → wait `kUndoWindow + 1s` via `tester.pump` → assert `pending_transactions` table has zero matching rows AND the recurring rule's `next_due_date` is **unchanged**.

Total integration scope is one file, three flows, ties together repo + controller + widget + the recurring slice's generation pass.

### No test removals

Wave 3's existing home tests assert behaviors that are still true (day nav, summary strip, swipe-delete on transactions). The `pending_badge.dart` widget itself is unchanged — only its host moved from the day-nav header to the new section header. The Wave 3 home tests don't assert the badge's location, so they're unaffected.

---

## Out of scope (defer)

- **Dedicated Pending Transactions screen.** All pending review happens inline on Home in this MVP of the feature.
- **Per-row edit-before-approve.** The "open Add Transaction form pre-filled" path was considered and rejected for v1. Variable-amount cases (utility bills) currently require: tap the rule → edit the rule's amount in `/settings/recurring/:id` → wait for next cold start → approve. A future Phase 2 plan can add an edit shortcut.
- **Pause-rule shortcut from the Skip snackbar.** The skip action only deletes the pending row; the parent rule continues to generate next month's occurrence. Adding a "Pause rule" action to the SnackBar is intentionally deferred.
- **Per-day pending anchoring.** All pending rows render in the sticky section regardless of the day the user is viewing. A future redesign could anchor each row to its `date` (e.g., "this pending row only appears when you navigate to May 8"); this version optimizes for discoverability.
- **Cap-hit / generation-failure banner on Home.** Per-rule errors surface on the rule tile in `/settings/recurring`; no Home-level surface exists. Adding one is a future Phase 2 plan.
- **Blockchain pending UI.** Source-aware tiles (icon variations for `source = 'blockchain'`, address truncation, etc.) are explicitly NOT shaped in this spec. Wallet sync ships its own UI design.

---

## Decisions and Trade-offs

**Why a separate `PendingController`, not a folded-in `HomeController`.**
HomeController is already complex — day navigation, swipe-delete-undo, and the summary-strip aggregates. Adding a third stream + a second skip-undo timer doubles the controller's surface and risks state-drift bugs that wouldn't fail loudly in widget tests. The cost of a separate controller is two providers instead of one and the `PendingSection` widget tree being unaware of `selectedDay` (which is fine — pending is sticky regardless of day).

**Why one-tap approve, not edit-before-approve.**
The recurring use case explicitly targets fixed-amount cases (subscriptions, rent). Variable amounts (utility bills) are the long tail; the friction step of "edit amount inline" would slow the common case to optimize for the rare case. Users with variable bills can still approve and then edit on Home (existing transaction edit flow) or pause/edit the rule directly.

**Why sticky-section-above-list, not anchored-to-date.**
"Pending" needs to be visible to be acted on. Anchoring to a specific day means rules dated days ago are invisible until the user navigates back — which they likely won't, because the Home day-nav skips empty days, and a day with only pending rows might be skipped. Sticky-at-top is the simpler, more discoverable shape; the trade-off is that the badge count grows visible across the whole top of Home if the user has many overdue rules.

**Why the grey-to-green animation, not an instant DB write.**
A pure stream-driven approve looks like the row "blinks away" — no acknowledgement. The 200 ms animation gives a tangible "I committed this" feedback before the visual stream propagation collapses the row. The total perceived sequence (~350 ms) is still snappier than a route-push-then-confirm flow.

**Why `homePendingSkippedSnack` instead of "Pending row deleted."**
"Skipped" matches the user's mental model — they're declining one occurrence, not deleting data. The actual DB row is deleted, but exposing that vocabulary in the UI would imply data loss.

**Why no surface for cold-start generation failures on Home.**
The bootstrap refactor explicitly accepted "Generation failures must not crash or block startup" and discarded the result. Adding a Home-level banner for this would re-introduce the surface area the refactor removed. Per-rule `lastError` on the management screen is the safety net; it's discoverable enough for the rare failure case.

---

## Acceptance Criteria

1. A user with one or more rules generating pending rows lands on Home and sees a "Pending · N items" section between the day-nav header and the day's transaction list.
2. Tapping the Approve circle on a pending row animates grey → green over 200 ms, then within ~350 ms total the row leaves the section and a `TransactionTile` appears in today's transaction list with the same amount, currency, category, account, memo, and date.
3. Swipe-left on a pending row reveals a red Skip action. Tapping Skip hides the row, shows a SnackBar with `commonUndo`. Tapping Undo within 4 s restores the row. Past 4 s, the pending row is deleted from the DB and the recurring rule is unchanged.
4. The section auto-hides (`SizedBox.shrink()`) when there are no pending rows; users without recurring rules see Home identical to its Wave 3 shape.
5. `flutter analyze` passes; the full test suite passes; the new ARB keys appear in all three locales and in `_expectedEnKeys`.
6. Approve / Skip failures surface `errorSnackbarGeneric` and leave the row in place.
7. The recurring rule's `next_due_date` is unchanged by Approve and Skip.
