# Recurring Transactions — Design Spec

## Overview

Recurring transactions allow users to define rules that auto-generate pending transactions on a schedule (daily, weekly, monthly, yearly). Generated items appear in the pending transactions pipeline for user approval, same as blockchain wallet sync items. This is a Phase 2 feature per `PRD.md`.

**Goal:** A user can define a fixed-amount recurring rule (e.g., "Rent, monthly on the 1st"), and on the next app open after a due date, a pending transaction is generated and surfaced in the Pending Transactions screen for one-tap approval.

**Acceptance criterion:** A monthly rule created on day D generates exactly one pending transaction on the next app open at or after day D, with `amount`, `currency`, `category_id`, `account_id`, and `memo` copied from the rule, and `next_due_date` advanced by one month with month-end clamping. Re-opening the app on the same day produces no duplicate.

**Scope decisions (from brainstorming):**
- Recurrence patterns: daily, weekly, monthly, yearly (standard intervals only, no custom N-day/N-week)
- Transaction types: both expense and income
- End conditions: indefinite only (no end date or max occurrence count)
- Generation timing: on app open (matches wallet sync pattern)
- Approval flow: review + approve with pre-filled data (same as wallet sync)
- Entry point: Settings → Recurring Transactions, dedicated form screen for create/edit
- Rule management: pause + resume + delete (delete = archive in DB; no archived-rules view in v1)

The trade-offs behind these choices and their out-of-scope upgrade paths are spelled out in the **Decisions and Trade-offs** section at the bottom.

---

## Prerequisites

This feature depends on Phase 2 infrastructure that does not yet exist in the codebase. The dependencies fall into two groups:

**Group A — must ship in the same migration as this feature:**

1. **`pending_transactions` table** — the universal staging table (with `PendingTransactionDao`, `PendingTransactionRepository`, `PendingTransaction` domain model). The recurring generation engine inserts into this table.
2. **`recurring_rules` table** — owned by this design.
3. **`wallet_addresses`, `exchange_rates`, token rows in `currencies`** — owned by separate Phase 2 designs.

These tables are introduced together in the v3 → v4 schema migration (`PRD.md:498`). The migration cannot be partial: `pending_transactions.recurring_rule_id REFERENCES recurring_rules` requires both tables to exist in the same step. **This design therefore does not ship until the v4 base migration plan that creates all four tables is ready and merged.** The migration itself is owned by the Phase 2 base-migration plan (separate doc); this design contributes only the `recurring_rules` slice.

**Group B — separate concurrent plan:**

1. **Pending Transactions UI** (`features/pending_transactions/`) — the review/approve/reject screen. Owned by a separate Phase 2 plan in the same milestone. This recurring design produces pending rows; the Pending Transactions plan is responsible for displaying and acting on them. Without it, generated items accumulate in the database with no user-visible surface.

**Implementation ordering inside this design:** v4 base migration → `RecurringRulesRepository` → `RecurringGenerationUseCase` → bootstrap wiring → management screen → form screen.

**`domain/` layer note:** The PRD pre-decides that Phase 2 use cases live in `lib/domain/` (`PRD.md` → *Folder Structure*). This feature is the first to land there, so it establishes the file conventions. The layer is not justified by this feature alone — `wallet_sync_use_case.dart` and `approve_pending_transaction_use_case.dart` follow.

---

## Data Model — `recurring_rules` Table

| Column             | Type     | Constraints                                                                                                      |
|--------------------|----------|------------------------------------------------------------------------------------------------------------------|
| id                 | INTEGER  | PRIMARY KEY AUTO                                                                                                 |
| name               | TEXT     | NOT NULL — user-friendly label ("Netflix", "Rent")                                                               |
| amount_minor_units | INTEGER  | NOT NULL — fixed amount per occurrence                                                                           |
| currency           | TEXT     | NOT NULL REFERENCES currencies(code)                                                                             |
| category_id        | INTEGER  | NOT NULL REFERENCES categories(id)                                                                               |
| account_id         | INTEGER  | NOT NULL REFERENCES accounts(id)                                                                                 |
| memo               | TEXT     | nullable — pre-filled on each generated item                                                                     |
| frequency          | TEXT     | NOT NULL — `'daily'`, `'weekly'`, `'monthly'`, `'yearly'`                                                        |
| day_of_week        | INTEGER  | nullable — 0=Sun..6=Sat, required when frequency='weekly'                                                        |
| day_of_month       | INTEGER  | nullable — 1-31, required when frequency='monthly'. Clamps to last day of shorter months (e.g., Jan 31 → Feb 28) |
| month_of_year      | INTEGER  | nullable — 1-12, required when frequency='yearly'                                                                |
| is_active          | BOOL     | DEFAULT true — false = paused                                                                                    |
| is_archived        | BOOL     | DEFAULT false — true = soft-deleted                                                                              |
| next_due_date      | DATETIME | NOT NULL — denormalized for fast "which rules are due?" queries on app open                                      |
| created_at         | DATETIME | NOT NULL                                                                                                         |
| updated_at         | DATETIME | NOT NULL                                                                                                         |

### Invariants

- `next_due_date` is recalculated after each generation: advance by the frequency interval
- **Initial `next_due_date` calculation** (set on rule creation):
  - **daily:** `today` (rule fires today on next app open if today ≥ creation date)
  - **weekly:** the next date on or after today whose weekday matches `day_of_week`
  - **monthly:** the next date on or after today whose day matches `day_of_month`, clamped to the last day of the month if shorter (e.g., creating on Mar 5 with `day_of_month=31` → Mar 31; creating on Feb 5 with `day_of_month=31` → Feb 28/29)
  - **yearly:** the next date on or after today whose `(month_of_year, day_of_month)` match, clamped for leap years (Feb 29 on a non-leap year → Feb 28)
- **Day-of-month anchor:** advancing always anchors on `rule.day_of_month`, **not** on the previously fired date. After clamping `day_of_month=31` to Feb 28, the next advance returns to Mar 31, not Mar 28
- Pausing sets `is_active = false`; resuming recalculates `next_due_date` from today using the same formula as Initial calculation above (missed periods while paused are skipped — the rule starts generating from the resume date, not catching up on missed occurrences)
- A rule with pending transactions in `pending_transactions` can be paused but not hard-deleted (archive-on-delete pattern, same as categories/accounts). Soft-delete sets `is_archived = true` and `is_active = false`
- `amount_minor_units` is fixed per rule — the user edits the amount on the pending item if it varies (e.g., utility bills)
- **Edit propagation:** Edits to a rule (amount, category, account, memo, frequency, etc.) only affect future generations. Already-generated pending items are left untouched — the user can edit or reject them individually from the Pending Transactions screen. The edit form surfaces this with an inline notice when there are unapproved pending items for the rule (see *UI Design — Edit form*)
- `day_of_week` uses 0=Sunday, 6=Saturday (US convention). Note: Dart's `DateTime.weekday` uses 1=Monday..7=Sunday — the repository/DAO must map between conventions when calculating next due dates
- Month-end clamping: if `day_of_month = 31` and next month has 30 days, use 30. Feb 29/30/31 → Feb 28 (or 29 in leap year)
- **Transaction type is derived from category, not stored on the rule.** Same as `transactions` — the form's type toggle controls which categories are shown, but the rule stores only `category_id`. The type is derived from `categories.type` at generation time and at display time. This is consistent with the PRD's "no third type value" principle
- **Archived references rejected:** Creating or editing a rule with an archived category, account, or currency is rejected at the repository layer with a typed exception. The category picker and account selector in the form filter out archived entries (same as transaction form)
- **Frequency-conditional field validation:** The repository rejects inserts/updates where frequency='weekly' and `day_of_week` is null, or frequency='monthly' and `day_of_month` is null, or frequency='yearly' and (`month_of_year` is null or `day_of_month` is null). The form UI shows inline validation errors for missing required fields before save is enabled. Frequency='daily' requires no additional fields
- `next_due_date` is stored as a date-only value (midnight in device-local timezone). The generation engine truncates `DateTime.now()` to date via `DateUtils.dateOnly` before comparison. The idempotency check `(recurring_rule_id, date)` is exact because both sides are date-only. **Time-zone trade-off:** the persisted timestamp is "midnight in the device-local zone at the time the rule was last advanced." A user crossing a time-zone boundary or experiencing DST may see ±1 day drift on the day of travel/transition. This is accepted v1 behavior — see *Decisions and Trade-offs*
- Archived rules are hidden from the management list but their existing pending items remain visible in the Pending Transactions screen
- Categories, accounts, and currencies referenced by active recurring rules participate in the same archive/delete guards as transactions and shopping-list items: a category, account, or currency referenced by any active rule cannot be hard-deleted

### Generation Atomicity and Catch-up

- **Per-rule atomicity:** the (insert pending row + advance `next_due_date` + update rule) sequence runs inside a single `AppDatabase.transaction { }`. A crash, exception, or process kill mid-sequence rolls back both the insert and the advance, preserving the invariant that `next_due_date` always points at the next un-generated occurrence. Without this wrapper, an interrupted generation can leak a pending row without advancing the rule, and the idempotency guard would then permanently skip future advances for that rule
- **Catch-up cap:** when generation runs, each rule produces at most **12** missed occurrences in a single `execute()` call. If more than 12 periods have passed since `next_due_date`, the engine fast-forwards `next_due_date` to the most recent matching occurrence and generates only that one. This bounds startup work (12 daily ≈ 2 weeks; 12 weekly ≈ 3 months; 12 monthly ≈ 1 year; 12 yearly ≈ 12 years) and prevents pending-list explosion after long absences. The user can backfill any older missed periods manually via the regular Add Transaction flow
- **Idempotency:** the application-level `(recurring_rule_id, date)` check is backed by a partial UNIQUE index on `pending_transactions(recurring_rule_id, date) WHERE source = 'recurring' AND recurring_rule_id IS NOT NULL`. This guarantees the database rejects a duplicate insert even if two writers race; the application check exists as a fast-path skip to avoid hitting the constraint in the common case

### Relation to `pending_transactions`

The `pending_transactions` table (Group A prerequisite) provides `source = 'recurring'` and `recurring_rule_id` FK. The recurring generation engine inserts rows with these fields set.

**One schema addition this design contributes to `pending_transactions`:** a partial UNIQUE index `idx_pending_recurring_unique ON pending_transactions(recurring_rule_id, date) WHERE source = 'recurring' AND recurring_rule_id IS NOT NULL`. This is the database-level guarantee behind the idempotency claim. The Pending Transactions base-migration plan owns the table; this design owns this single index addition and the index must land in the same v4 migration as the table.

### Schema Migration

This feature's `recurring_rules` table is created as part of the v3 → v4 Phase 2 migration (`PRD.md:498`). The full v4 migration is owned by the Phase 2 base-migration plan and bundles `pending_transactions`, `wallet_addresses`, `exchange_rates`, and token rows in `currencies` alongside `recurring_rules`. This design's contribution to that migration:

- Create `recurring_rules` table
- Add index on `recurring_rules(is_active, next_due_date)` for the "which rules are due?" query on app open
- Add index on `recurring_rules(is_archived)` for management list filtering
- Add partial UNIQUE index on `pending_transactions(recurring_rule_id, date) WHERE source = 'recurring' AND recurring_rule_id IS NOT NULL` (see *Relation to `pending_transactions`*)
- FK `pending_transactions.recurring_rule_id REFERENCES recurring_rules(id)` requires `recurring_rules` to be created **before** `pending_transactions` in the v4 step (or a deferred FK)
- Migration tested on both empty and seeded v3 databases, including the case where a v3 user upgrades and immediately creates a recurring rule

---

## Architecture — Use Case Pattern

Mirrors the wallet sync architecture from `PRD.md`. This feature introduces the `domain/` layer for the first time in this codebase. Future Phase 2 use cases (e.g., `wallet_sync_use_case.dart`, `approve_pending_transaction_use_case.dart`) follow the same `domain/` convention.

### Layer Boundaries

| Component                     | Layer           | Responsibility                                                                                                                                                                                                 |
|-------------------------------|-----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RecurringRuleDao`            | Data/DAO        | Thin SQL wrapper for `recurring_rules` table                                                                                                                                                                   |
| `RecurringRulesRepository`    | Data/Repository | SSOT for `recurring_rules`. Maps Drift rows → Freezed domain models. Enforces invariants (pause/delete guards, clamping)                                                                                       |
| `RecurringRule`               | Data/Model      | Freezed domain model                                                                                                                                                                                           |
| `RecurringGenerationUseCase`  | Domain          | Scans active rules, creates pending items, advances `next_due_date`. Coordinates `RecurringRulesRepository` + `PendingTransactionRepository` inside an `AppDatabase.transaction { }` per rule                  |
| `RecurringRulesController`    | UI/Controller   | Exposes management state + commands (create/edit/pause/resume/delete). Uses `StreamNotifier` for reactive list                                                                                                 |
| `RecurringRuleFormController` | UI/Controller   | Owns the create/edit form state and save commands. Independent of `TransactionFormController`                                                                                                                  |
| `RecurringRulesScreen`        | UI/Widget       | Management list screen                                                                                                                                                                                         |
| `RecurringRuleFormScreen`     | UI/Widget       | Create/edit form. Composes shared sub-widgets (`KeypadCalculator`, `CategoryPicker`, `AccountSelector`, `CurrencySelector`, `MemoField`) — does **not** reuse `TransactionFormScreen` (see *UI Design — Form*) |

### Repository Contract — `RecurringRulesRepository`

```dart
abstract interface class RecurringRulesRepository {
  // Read
  Stream<List<RecurringRule>> watchActive();             // is_archived=false, sorted by (is_active desc, next_due_date asc, name asc)
  Stream<List<RecurringRule>> watchDue(DateTime today);  // is_active=true, is_archived=false, next_due_date <= today
  Future<RecurringRule?> getById(int id);
  Future<int> countPendingForRule(int id);               // for the edit-form inline notice

  // Write
  Future<int> insert(RecurringRuleDraft draft);          // returns new id; computes initial next_due_date from frequency + today
  Future<void> update(int id, RecurringRuleDraft draft); // edits affect future generations only
  Future<void> setActive(int id, {required bool active}); // pause = false, resume = true; resume recomputes next_due_date from today
  Future<void> archive(int id);                          // soft-delete: is_archived=true, is_active=false
  Future<void> advanceAfterGeneration(int id, DateTime newNextDueDate); // called by use case inside its own transaction

  // Hard-delete (only for unused rules; throws otherwise)
  Future<void> hardDelete(int id);
}

// Exception types declared alongside the repository:
//   ArchivedReferenceException   — thrown by insert/update when category, account, or currency is archived
//   RuleHasPendingItemsException — thrown by hardDelete when the rule has any pending_transactions row
//   FrequencyFieldsMissingException — thrown by insert/update when frequency-conditional fields are null
```

`RecurringRuleDraft` is a Freezed value object carrying the user's form input (no `id`, no `next_due_date`, no `is_active`, no `is_archived`, no timestamps — those are repository-managed).

### Generation Engine — `RecurringGenerationUseCase`

**Provider:** Declared as `@riverpod` in `lib/domain/recurring_generation_use_case.dart`, depending on `recurringRulesRepositoryProvider` and `pendingTransactionRepositoryProvider`. Generated file: `recurring_generation_use_case.g.dart`. The use case takes a `Clock` (or `DateTime Function()` seam) injected via override in tests.

**Trigger and bootstrap wiring:** Invoked from a `WidgetsBinding.instance.addPostFrameCallback` registered inside the root widget after `runApp(ProviderScope(...))` returns — i.e., the first frame has rendered and the Riverpod container exists. Concretely: the root widget reads `recurringGenerationUseCaseProvider` and calls `unawaited(useCase.execute())` in its post-frame callback. This is the same trigger window the future `wallet_sync_use_case` will use.

**`generationInProgress` flag:** Exposed as a top-level `Provider<bool>` derived from a `StateController<bool>` that the use case toggles at the start and end of `execute()`. The Pending Transactions screen consumes this flag to render a "Checking for new pending items…" banner so a user who lands on Pending immediately after cold start does not act on a pre-generation snapshot.

**Failure mode:** If `RecurringGenerationUseCase.execute()` throws (DB corruption, unexpected null), the error is caught and logged via the existing logger. The app continues normally; generation retries on next app open. Silent-and-log is intentional — see *Decisions and Trade-offs*. Per-rule errors inside the loop are caught individually so one bad rule does not abort generation for the rest.

**Startup performance:** Generation does not block the first frame (it runs from a post-frame callback). The pending badge count on Home updates reactively when generation completes and the `pending_transactions` stream emits.

**Flow:**

```
First frame rendered
  → addPostFrameCallback → unawaited(useCase.execute())
    → set generationInProgress = true
    → today = DateUtils.dateOnly(DateTime.now())
    → query recurring_rules WHERE is_active = true AND is_archived = false AND next_due_date <= today
    → for each due rule (caught per-rule):
        AppDatabase.transaction:
          generated = 0
          loop while rule.next_due_date <= today AND generated < 12:
            → fast-path skip: SELECT 1 FROM pending_transactions
              WHERE recurring_rule_id = rule.id AND date = rule.next_due_date
              → if row exists, advance next_due_date and continue (do not insert)
            → INSERT INTO pending_transactions:
                source = 'recurring'
                recurring_rule_id = rule.id
                amount_minor_units = rule.amount_minor_units
                currency = rule.currency
                category_id = rule.category_id
                account_id = rule.account_id
                memo = rule.memo
                date = rule.next_due_date (date-only, midnight)
                fetched_at = now
              (the partial UNIQUE index is the DB-level guarantee against duplicates)
            → advance rule.next_due_date by frequency interval (anchored on rule.day_of_month / day_of_week / month_of_year, NOT on previous fired date):
                daily:   +1 day
                weekly:  +7 days
                monthly: rule.day_of_month in next month (clamp to last day)
                yearly:  (rule.month_of_year, rule.day_of_month) in next year (clamp for leap year)
            → generated += 1
          if generated == 12 AND rule.next_due_date <= today:
            → fast-forward rule.next_due_date to the most recent matching occurrence at or before today
              (catch-up cap reached — older missed periods are dropped; user can backfill manually)
          → UPDATE rule SET next_due_date, updated_at
    → set generationInProgress = false
```

**Edge cases:**
- **Clamping:** If `day_of_month = 31` and next month has 30 days → use 30. Feb 29/30/31 → Feb 28 (or 29 in leap year). The rule's `day_of_month` column is unchanged; clamping affects only the materialized `next_due_date`
- **Day-of-month return-to-31:** A rule with `day_of_month = 31`, after generating Feb 28, advances to Mar 31, not Mar 28 (anchor is `rule.day_of_month`, not previous fired date)
- **Idempotency:** The fast-path skip + partial UNIQUE index together guarantee one row per `(recurring_rule_id, date)` regardless of how many times the user opens the app on the same day or whether multiple writers race
- **Midnight boundary:** If the app opens at 23:59 and again at 00:01 (next day), the second open sees a new "today" and may generate the next occurrence if the rule is due. Correct — the idempotency guard is per-date, not per-day-of-week
- **Skipped periods (within cap):** If the user hasn't opened the app for 3 months and a monthly rule was due each month, all 3 missed occurrences generate as separate pending rows in chronological order (3 ≤ 12 cap)
- **Skipped periods (cap exceeded):** A daily rule untouched for 6 months produces only the 12 most recent missed daily occurrences; older periods are dropped and `next_due_date` jumps forward to the 13th-most-recent date. Documented in *Generation Atomicity and Catch-up*
- **Paused rules:** Skipped — `is_active = false` rules are not queried
- **Archived rules:** Skipped — `is_archived = true` rules are not queried
- **Time-zone / DST:** Comparison uses `DateUtils.dateOnly(DateTime.now())` against the persisted `next_due_date`. A user crossing a time-zone boundary or experiencing DST may see ±1 day drift on the day of travel; accepted v1 behavior
- **Clock manipulation:** If the user moves the device clock backward, `next_due_date` is now in the future relative to "today" and the rule will not fire until real time catches up. Forward jumps trigger up to the catch-up cap. No diagnostic; documented in *Decisions and Trade-offs*

### Domain Model — `RecurringRule`

```dart
@freezed
abstract class RecurringRule with _$RecurringRule {
  const factory RecurringRule({
    required int id,
    required String name,
    required int amountMinorUnits,
    required Currency currency,      // resolved from TEXT FK by repository (same as Transaction)
    required int categoryId,
    required int accountId,
    String? memo,
    required String frequency,       // 'daily', 'weekly', 'monthly', 'yearly'
    int? dayOfWeek,                  // 0=Sun..6=Sat
    int? dayOfMonth,                 // 1-31
    int? monthOfYear,                // 1-12
    required bool isActive,
    required bool isArchived,
    required DateTime nextDueDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RecurringRule;
}
```

Note: The `currency` field is the full `Currency` value object (from `data/models/currency.dart`), resolved from the TEXT FK `currencies.code` by `RecurringRulesRepository` on read. This follows the same pattern as `TransactionRepository` — the Drift column stores the code string, the domain model carries the full object.

---

## UI Design

### Entry Point

Settings screen gets a new "Recurring Transactions" tile (same pattern as "Manage Categories" / "Manage Accounts"). Tapping opens the management screen.

### Management Screen — `features/recurring/recurring_rules_screen.dart`

**List structure**

- Single flat list (`ListView.builder`), excluding archived rules
- **Sort order:** `is_active` desc, then `next_due_date` asc, then `name` asc — active rules at the top sorted by soonest due, paused rules sunk to the bottom sorted alphabetically. Sort is server-side (the repository's `watchActive` query); the UI does not re-sort
- **No grouping or section headers.** The visual demotion of paused rules (see *Tile* below) is enough; group headers add noise for the expected ≤20-rule case

**Tile** (each row of the list)

- Leading: a small filled circle in the rule's category color
- Title: the rule's `name` (single line, ellipsis on overflow)
- Subtitle line 1: amount + currency (e.g., `$15.99 USD`), formatted via `MoneyFormatter` from minor units
- Subtitle line 2: frequency label (e.g., "Monthly on the 15th", "Every Wednesday", "Daily")
- Trailing: next-due text. Active: relative date (`recurringTileNextDue("Apr 15")` → "Next: Apr 15"). Paused: a "Paused" chip in the muted color, replacing the next-due date entirely (the persisted `next_due_date` is stale and not shown)
- Visual demotion for paused rules: tile content rendered at 60 % opacity

**States**

- **Loading** (initial Drift stream emission): full-screen `CircularProgressIndicator` centered
- **Empty:** `RecurringRulesEmptyState` widget — illustration (reuse the empty-list asset already used by Categories/Accounts), heading `recurringEmptyHeading` ("No recurring rules yet"), body `recurringEmptyBody` ("Set up a rule for rent, subscriptions, or any expense that repeats. Ledgerly will create a pending transaction for you on the due date."), primary button `recurringEmptyCta` ("Create rule") that opens the create form
- **Error:** centered text `recurringRulesLoadError` ("Couldn't load your rules.") + retry button. Errors here are repository-stream failures and should be rare

**Swipe actions** (using the existing `Dismissible` + undo-snackbar pattern shared by Home and Shopping List)

- **Swipe left:** label is `recurringSwipePause` ("Pause") on active rules, `recurringSwipeResume` ("Resume") on paused rules. Toggle is committed immediately on swipe (no undo) since it's reversible. A confirmation snackbar `recurringPausedSnack` ("Paused — Netflix") / `recurringResumedSnack` ("Resumed — Netflix, next due Apr 30") shows for 2 seconds. Background color: amber for pause, green for resume. Icon: `Icons.pause` / `Icons.play_arrow`. Optimistic update — tile re-renders immediately, the stream sync confirms
- **Swipe right:** label is `recurringSwipeDelete` ("Delete") — note the user-facing label is **Delete**, not "Archive", because there is no v1 path to recover archived rules (see *Decisions and Trade-offs*). The swipe shows a 4-second undo snackbar; if the user navigates away during the window, the timer cancels and the deletion is committed immediately on navigation (matching `ShoppingListController`'s pattern). Icon: `Icons.delete_outline`. Background: error color
- **Race between swipe and tap:** the row is non-tappable while the dismiss animation is in flight (Flutter's default `Dismissible` behavior)

**Tap a rule** → opens the edit form at `/settings/recurring/:id` (see *Routing*). The same row is not tappable during the swipe animation

**FAB** → primary FAB labeled `recurringFabNew` ("New rule") + `Icons.add`, opens `/settings/recurring/new`. On ≥600dp the FAB is replaced by an app-bar "+" action (existing adaptive pattern from Manage Accounts)

**Adaptive ≥600dp:** the management list stays a single full-width column inside the constrained shell; no master-detail. The form opens as a constrained dialog, matching `/settings/manage-accounts/:id`

**Accessibility**

- Tile has a Semantics label combining name + amount + frequency + next-due (e.g., "Netflix, $15.99 USD, monthly on the 15th, next due April 15") so screen readers announce the row in one phrase
- Swipe actions expose `Dismissible` action labels via Semantics (`recurringSwipePause`, etc.) for VoiceOver/TalkBack
- Pause indicator chip has `Semantics(label: "Paused")`

### Form Screen — `RecurringRuleFormScreen` (dedicated, not reused)

A standalone screen at `lib/features/recurring/recurring_rule_form_screen.dart`, **not** a mode of `TransactionFormScreen`. It composes the same shared sub-widgets that the transaction form uses (`KeypadCalculator`, `CategoryPicker`, `AccountSelector`, `CurrencySelector`, `MemoField`) but owns its own state, controller, and save flow.

Reasoning: `TransactionFormState` already carries 4 sealed `TransactionFormMode` variants (Add, Duplicate, Edit, EditShoppingListDraft) tightly bound to transaction semantics — `date`, `currencyTouched`, `shoppingListItemId`, `selectedAccountIsArchived`, `submissionAction` enum, getters like `canSaveDraft`/`canConvertDraft`. Threading a 5th mode for an unrelated domain object (rule with frequency, weekday, etc.) would expand the controller from ~800 LoC to ~1200 LoC, mix two save targets in one method, and tax every future transaction-form change with rule-mode considerations. A dedicated form is simpler to read, test, and evolve. The shared sub-widgets keep the visual consistency without coupling the controllers.

**Layout** (matches the transaction form structurally so muscle memory transfers):

```
Scaffold(resizeToAvoidBottomInset: false)
└─ SafeArea
   └─ Column
      ├─ AppBar (title: "New rule" / rule.name; trailing save action)
      ├─ Expanded scroll region:
      │  ├─ Expense/Income segmented control            (filters CategoryPicker)
      │  ├─ Name field                                   (TextFormField, required, max 60 chars)
      │  ├─ Amount display (read-only, driven by keypad)
      │  ├─ Currency selector tile
      │  ├─ Account selector tile                        (filters out archived accounts)
      │  ├─ Category picker entry                        (filters by type, archived hidden)
      │  ├─ Recurrence section (see below)
      │  ├─ Memo field                                   (optional)
      │  ├─ [edit mode only] Pending-items inline notice (see below)
      │  └─ [edit mode only] Delete button               (destructive style, bottom of scroll)
      └─ KeypadCalculator (fixed-height, calculator-style)
```

**Recurrence section**

- Frequency dropdown (`recurringFrequencyDaily` / `Weekly` / `Monthly` / `Yearly`)
- Conditional fields (rendered with an animated cross-fade so the form height transitions smoothly):
  - **Daily:** no extra field; helper text `recurringDailyHelper` ("Generates one pending transaction every day from today.")
  - **Weekly:** seven-chip horizontal selector (Sun–Sat). Each chip is at minimum 48 × 48 dp (the seven chips wrap to a second row on screens narrower than 7 × 48 = 336 dp); single-select. Active chip uses the primary color
  - **Monthly:** stepper-style number field (1–31). Below the field: persistent helper text `recurringDayOfMonthHint` ("If the month is shorter, the rule uses the last day of that month.") — always visible, not an error. The value 31 is **accepted** without an error; clamping happens at generation
  - **Yearly:** month dropdown (Jan–Dec) + day-of-month stepper (1–31). Same `recurringDayOfMonthHint` shown below

**Inline notice (edit mode only)**

When the rule has ≥1 unapproved pending item (`countPendingForRule(id) > 0`), the form shows a non-blocking notice above the Recurrence section: `recurringEditWillNotAffectPending` ("You have N pending item(s) from this rule. Edits below won't change them — review them in Pending Transactions."). The body of the notice is a plain `Text`; no link to Pending in v1 (avoids cross-feature navigation polish).

**Save / Cancel**

- App-bar trailing action label: `recurringSaveCreate` ("Create") on create, `recurringSaveUpdate` ("Save") on edit. Disabled until name is non-empty, amount > 0, frequency-conditional fields are valid, and category + account are selected
- Cancel: app-bar leading "Back" arrow with the standard "Discard changes?" confirmation if the form is dirty (matches transaction form)
- Save success: pop back to the management list, snackbar `recurringSavedCreate` ("Rule created") or `recurringSavedUpdate` ("Rule updated")

**Delete (edit mode only)**

- Destructive button at the bottom of the form: `recurringDeleteRule` ("Delete rule")
- Tapping shows a confirmation modal `recurringDeleteConfirm` ("Delete this rule? Pending items already generated will remain in your queue."); confirming archives the rule and pops back to the management list with a snackbar `recurringDeletedSnack` ("Rule deleted") + a 4-second Undo action that calls `setActive(true)` and clears the archive

### User Flow — Create → First Generation → Approve

1. Settings → Recurring Transactions tile → Management list (empty state on first run)
2. Tap "Create rule" → form opens with default frequency = Monthly, today's date pre-selected as the implicit anchor
3. Fill name, amount, account, category, frequency-conditional fields → tap "Create"
4. Pop to management list, snackbar "Rule created", new rule appears with `next_due_date` computed per *Initial `next_due_date` calculation*
5. **First generation:**
   - If `next_due_date == today` (e.g., user creates a daily rule), the post-frame callback in the same session does NOT generate (generation only runs on cold-start). The next cold-start at or after `next_due_date` generates the first pending item
   - If user wants to test, they cold-start the app
6. Pending Transactions screen (separate plan) shows the new pending item under a "Recurring" source group. Approve → `transactions` row inserted, pending row deleted. Reject → pending row deleted, rule unaffected, next occurrence still generates on its scheduled date

### Pending Transactions Integration

Recurring pending items appear in the Pending Transactions screen (separate Phase 2 plan) under a `recurringSourceHeader` ("Recurring") source group, distinct from the blockchain group `walletSyncSourceHeader` ("From wallet sync").

Each recurring tile shows:

- Leading: rule's category color dot
- Title: rule's name (e.g., "Netflix")
- Subtitle line 1: amount + currency
- Subtitle line 2: due date (e.g., "Due Apr 15")
- Trailing: same approve / reject affordances the Pending Transactions plan defines for blockchain items

**Edge case — parent rule archived after item generated:** the pending row carries the snapshot data (amount, category, account, memo, currency) at generation time, so it remains fully renderable even if the rule was archived. The tile shows the rule's name from the snapshot (or "Deleted rule" if the snapshot is unavailable, though in practice the row stores name copy for this reason). The Pending Transactions plan owns this snapshot logic; this design only requires that `pending_transactions` carry enough columns to render without joining `recurring_rules`.

**Approve / reject flow:** approve inserts into `transactions` and deletes the pending row (preserving currency + amount). Reject deletes the pending row only. Neither affects the parent rule — the next due date is already advanced.

---

## Routing

New routes under Settings branch:

```
/settings/recurring              → RecurringRulesScreen (management list)
/settings/recurring/new          → RecurringRuleFormScreen (modal push, create)
/settings/recurring/:id          → RecurringRuleFormScreen (modal push, edit)
```

Same adaptive treatment as `/settings/manage-accounts/:id` on ≥600dp: routes use `fullscreenDialog: true` with `parentNavigatorKey` so the form opens as a constrained dialog instead of a full-screen route on large viewports.

---

## Folder Structure

```
lib/
  data/
    database/
      tables/
        recurring_rules_table.dart          # NEW — Drift table definition
      daos/
        recurring_rule_dao.dart             # NEW — thin SQL wrapper
    models/
      recurring_rule.dart                   # NEW — Freezed domain model
      recurring_rule.freezed.dart           # generated
      recurring_rule_draft.dart             # NEW — Freezed form-input value object
      recurring_rule_draft.freezed.dart     # generated
    repositories/
      recurring_rules_repository.dart       # NEW — SSOT for recurring_rules (+ exception types)
  domain/
    recurring_generation_use_case.dart      # NEW — scans rules, creates pending items
    recurring_generation_use_case.g.dart    # generated (riverpod_generator)
  features/
    recurring/
      recurring_rules_screen.dart           # NEW — management list
      recurring_rules_controller.dart       # NEW — list state + pause/resume/delete commands
      recurring_rules_state.dart            # NEW — Freezed state (loading | empty | data | error)
      recurring_rule_form_screen.dart       # NEW — dedicated create/edit form
      recurring_rule_form_controller.dart   # NEW — form state + save commands
      recurring_rule_form_state.dart        # NEW — Freezed form state
      recurring_rules_providers.dart        # NEW — slice-local helper providers (e.g., generationInProgressProvider)
```

Note: `domain/` is introduced for the first time by this feature. `features/recurring/` is also a new subfolder, extending the feature list in `PRD.md` → *Folder Structure*. The `PendingTransactionRepository` and related data-layer files are part of the `pending_transactions` prerequisite (see Prerequisites section) and are not listed here.

---

## Changes to Existing Files

| File                                          | Change                                                                                                                                                                               |
|-----------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `app_database.dart`                           | Add `RecurringRules` table + `RecurringRuleDao` to `@DriftDatabase` annotation; bump `schemaVersion` to 4 (in coordination with the v4 base-migration plan)                          |
| `lib/app/providers/repository_providers.dart` | Add `recurringRulesRepositoryProvider` (`@riverpod` with `dependencies: [appDatabaseProvider]`, matching existing entries)                                                           |
| `lib/app/app.dart` (root widget)              | Register a post-frame callback that reads `recurringGenerationUseCaseProvider` and calls `unawaited(useCase.execute())` once on cold-start                                           |
| `router.dart`                                 | Add `/settings/recurring`, `/settings/recurring/new`, `/settings/recurring/:id` routes (modal push on <600dp; constrained dialog on ≥600dp matching `/settings/manage-accounts/:id`) |
| `settings_screen.dart`                        | Add "Recurring Transactions" tile                                                                                                                                                    |
| `l10n/app_en.arb`                             | Add recurring-related strings (see *l10n keys* below)                                                                                                                                |
| `l10n/app_zh_TW.arb`                          | Add recurring-related strings (Traditional Chinese)                                                                                                                                  |
| `l10n/app_zh_CN.arb`                          | Add recurring-related strings (Simplified Chinese)                                                                                                                                   |

**Files NOT touched:** `transaction_form_screen.dart` and `transaction_form_state.dart` are unchanged. The recurring form is a dedicated screen (see *UI Design — Form*), so the existing transaction form keeps its current four-mode sealed union.

### l10n keys

The following keys must land in all three ARBs (`app_en.arb`, `app_zh_TW.arb`, `app_zh_CN.arb`). English values are listed; translators provide zh-TW and zh-CN.

| Key                                 | English                                                                                                                                 | Notes                                              |
|-------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------|
| `settingsRecurringTile`             | Recurring transactions                                                                                                                  | Settings entry-point label                         |
| `recurringRulesTitle`               | Recurring transactions                                                                                                                  | Management screen app-bar title                    |
| `recurringEmptyHeading`             | No recurring rules yet                                                                                                                  |                                                    |
| `recurringEmptyBody`                | Set up a rule for rent, subscriptions, or any expense that repeats. Ledgerly will create a pending transaction for you on the due date. |                                                    |
| `recurringEmptyCta`                 | Create rule                                                                                                                             |                                                    |
| `recurringFabNew`                   | New rule                                                                                                                                |                                                    |
| `recurringRulesLoadError`           | Couldn't load your rules.                                                                                                               |                                                    |
| `recurringRulesLoadRetry`           | Retry                                                                                                                                   |                                                    |
| `recurringTileNextDue`              | Next: {date}                                                                                                                            | Placeholder `{date}`                               |
| `recurringTilePaused`               | Paused                                                                                                                                  | Chip + Semantics label                             |
| `recurringFreqDailyLabel`           | Daily                                                                                                                                   |                                                    |
| `recurringFreqWeeklyLabel`          | Every {weekday}                                                                                                                         | e.g., "Every Wednesday"                            |
| `recurringFreqMonthlyLabel`         | Monthly on the {ordinal}                                                                                                                | e.g., "Monthly on the 15th"                        |
| `recurringFreqYearlyLabel`          | Yearly on {month} {ordinal}                                                                                                             | e.g., "Yearly on April 15th"                       |
| `recurringSwipePause`               | Pause                                                                                                                                   |                                                    |
| `recurringSwipeResume`              | Resume                                                                                                                                  |                                                    |
| `recurringSwipeDelete`              | Delete                                                                                                                                  | User-facing label for archive                      |
| `recurringPausedSnack`              | Paused — {ruleName}                                                                                                                     |                                                    |
| `recurringResumedSnack`             | Resumed — {ruleName}, next due {date}                                                                                                   |                                                    |
| `recurringDeletedSnack`             | Rule deleted                                                                                                                            | + 4-second Undo                                    |
| `recurringFormCreateTitle`          | New rule                                                                                                                                |                                                    |
| `recurringFormEditTitle`            | Edit rule                                                                                                                               | Used when rule.name is empty during transient edit |
| `recurringFormNamePlaceholder`      | Rule name                                                                                                                               |                                                    |
| `recurringFrequencyDaily`           | Daily                                                                                                                                   |                                                    |
| `recurringFrequencyWeekly`          | Weekly                                                                                                                                  |                                                    |
| `recurringFrequencyMonthly`         | Monthly                                                                                                                                 |                                                    |
| `recurringFrequencyYearly`          | Yearly                                                                                                                                  |                                                    |
| `recurringDailyHelper`              | Generates one pending transaction every day from today.                                                                                 |                                                    |
| `recurringDayOfMonthHint`           | If the month is shorter, the rule uses the last day of that month.                                                                      | Always-visible hint, not error                     |
| `recurringFieldRequired`            | Required                                                                                                                                | Generic field-level validation copy                |
| `recurringSaveCreate`               | Create                                                                                                                                  |                                                    |
| `recurringSaveUpdate`               | Save                                                                                                                                    |                                                    |
| `recurringSavedCreate`              | Rule created                                                                                                                            |                                                    |
| `recurringSavedUpdate`              | Rule updated                                                                                                                            |                                                    |
| `recurringDeleteRule`               | Delete rule                                                                                                                             |                                                    |
| `recurringDeleteConfirm`            | Delete this rule? Pending items already generated will remain in your queue.                                                            |                                                    |
| `recurringEditWillNotAffectPending` | You have {count} pending item(s) from this rule. Edits below won't change them — review them in Pending Transactions.                   | ICU plural on `{count}`                            |
| `recurringSourceHeader`             | Recurring                                                                                                                               | Pending Transactions screen source group           |
| `recurringPendingDueLabel`          | Due {date}                                                                                                                              |                                                    |
| `recurringGenerationInProgress`     | Checking for new pending items…                                                                                                         | Banner on Pending screen during generation         |

---

## Testing Strategy

### Repository Tests (`test/unit/repositories/recurring_rules_repository.dart`)

- CRUD operations (insert, update, archive, hardDelete, getById, countPendingForRule)
- **Initial `next_due_date` calculation** per frequency on insert: daily today, weekly next-matching-weekday, monthly next-matching-day-with-clamp, yearly next-matching-(month, day) with leap-year clamp
- **Day-of-month anchor:** insert with `day_of_month=31` in March → next_due_date Mar 31; advance to April → Apr 30; advance to May → May 31 (anchor restored after February clamp)
- Pause/resume: `is_active` toggle, `next_due_date` recalculation on resume mirrors initial calculation
- `hardDelete` throws `RuleHasPendingItemsException` when pending rows reference the rule
- Archive sets `is_archived = true` and `is_active = false` and is allowed regardless of pending rows
- FK delete guard: hard-deleting a category/account/currency referenced by an **active** rule fails (delegated to existing repos)
- FK archive guard: archiving a category/account referenced by an active rule is allowed; the management screen's edit form rejects further edits to that rule until the user picks a non-archived replacement
- `ArchivedReferenceException` thrown on insert/update with an archived category, account, or currency
- `FrequencyFieldsMissingException` thrown when frequency-conditional fields are null on insert/update
- Stream emissions: `watchActive` emits sorted list (active first by next-due asc, paused at bottom by name) on each mutation
- `countPendingForRule` returns the right count after generation

### Use Case Tests (`test/unit/use_cases/recurring_generation_use_case.dart`)

Mock `RecurringRulesRepository` + `PendingTransactionRepository` via `mocktail`. Inject a fixed `Clock` for deterministic dates.

- Happy path: active rule with due date → pending row inserted, `next_due_date` advanced
- **Atomicity:** if `PendingTransactionRepository.insert` throws, the rule's `next_due_date` is NOT advanced (transaction rolls back). Re-running execute on a fresh container regenerates correctly
- **Idempotency (fast-path):** same rule, same date, run twice → only one pending row; second run skips via the fast-path SELECT
- **Idempotency (DB-level):** simulate the fast-path missing the row (race) and confirm the partial UNIQUE index rejects the duplicate insert
- **Catch-up cap:** daily rule with `next_due_date` 30 days in the past → exactly 12 pending rows generated, `next_due_date` fast-forwarded to today − 0 (the most recent matching occurrence)
- **Catch-up within cap:** monthly rule 3 months in the past → 3 pending rows, all advances persisted
- Paused rules skipped
- Archived rules skipped
- Multiple rules with different frequencies in one execute → all due items generated; an exception in rule A does not abort generation for rule B
- Edge cases: month-end clamping (Jan 31 → Feb 28, Aug 31 → Sep 30), leap year (Feb 29 → Feb 28 next year, then back to Feb 29 in the following leap year), Dec 31 → Jan 31 → Feb 28
- `generationInProgress` flag is true during execute and false after

### Controller Tests (`test/unit/controllers/recurring_rules_controller.dart` + `recurring_rule_form_controller.dart`)

- List controller state transitions: loading → data, loading → error, empty
- List commands: pause, resume, delete-with-undo, navigate-to-edit
- Form controller: initial state for create vs edit, name validation, frequency-conditional field validation, save command branches to `insert` or `update`, save disabled until valid
- Form controller: edit mode loads `countPendingForRule` and exposes the inline-notice flag
- Form controller: delete command calls `archive` and shows undo
- Mock repository via Riverpod `ProviderContainer` overrides

### Widget Tests (`test/widget/features/recurring/`)

- Management screen: rule list rendering, empty state, paused tile renders "Paused" chip and 60 % opacity, swipe-pause/swipe-resume label changes per state, swipe-delete snackbar with undo
- Form: frequency dropdown swap renders correct conditional fields (daily/weekly/weekly chips/monthly stepper/yearly month+day)
- Form: `recurringDayOfMonthHint` is always visible (not gated on error)
- Form: name required, amount > 0 required, weekly chip required for frequency=weekly, save action disabled until valid
- Form: edit mode shows `recurringEditWillNotAffectPending` when `countPendingForRule > 0`
- Form: delete confirmation modal + post-delete snackbar with undo
- Adaptive: at ≥600dp, form opens as a constrained dialog rather than full-screen
- Accessibility: tile Semantics label combines name/amount/frequency/next-due in one announcement
- Day-of-week chips render at minimum 48 × 48 dp, wrap to second row on narrow screens

### Integration Tests (`test/integration/recurring_transaction_test.dart`)

- Create rule with frequency=monthly day=15 on Mar 5 → `next_due_date` is Mar 15. Cold-start app on Mar 16 → pending row exists; approve → visible in Home; rule's `next_due_date` is Apr 15
- Idempotency: cold-start twice on the same day → exactly one pending row
- Pause rule → cold-start → no new pending rows. Resume → `next_due_date` recomputed from today
- Reject pending recurring item → removed from pending; rule's `next_due_date` already advanced; next cold-start does not re-create the rejected date
- Delete rule (archive) → no longer appears in management list; existing pending rows remain
- Catch-up cap end-to-end: cold-start with daily rule 30 days stale → 12 pending rows, `next_due_date` fast-forwarded
- Generation failure recovery: corrupt one rule, cold-start → other rules still generate; corrupt rule logs an error and does not produce a partial pending row

---

## Open Questions

None — all design decisions resolved during brainstorming.
