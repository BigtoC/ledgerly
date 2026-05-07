# Recurring Transactions — Design Spec

## Overview

Recurring transactions allow users to define rules that auto-generate pending transactions on a schedule (daily, weekly, monthly, yearly). Generated items appear in the pending transactions pipeline for user approval, same as blockchain wallet sync items. This is a Phase 2 feature per `PRD.md`.

**Scope decisions (from brainstorming):**
- Recurrence patterns: daily, weekly, monthly, yearly (standard intervals only, no custom N-day/N-week)
- Transaction types: both expense and income
- End conditions: indefinite only (no end date or max occurrence count)
- Generation timing: on app open (matches wallet sync pattern)
- Approval flow: review + approve with pre-filled data (same as wallet sync)
- Entry point: Settings → Recurring Transactions, reuse Add Transaction form widget for creation/edit
- Rule management: pause + resume + delete

---

## Prerequisites

This feature depends on Phase 2 infrastructure that does not yet exist in the codebase:

1. **`pending_transactions` table** — the universal staging table for auto-generated transactions. Must be created (with `PendingTransactionDao`, `PendingTransactionRepository`, `PendingTransaction` domain model) before the recurring generation engine can insert into it.
2. **`domain/` layer** — the use case layer. This feature introduces `domain/` for the first time. The `domain/` folder and its conventions are established by this feature.
3. **Pending Transactions UI** — the review/approve/reject screen. Recurring items appear alongside blockchain items in this screen. The screen must exist (or be built as part of the same plan) for users to act on generated items.

**Implementation ordering:** The `pending_transactions` data layer (table + DAO + repository + model) must ship first or alongside this feature. The recurring generation use case and management UI can ship after. The Pending Transactions UI can be built independently but is needed for the full user flow.

---

## Data Model — `recurring_rules` Table

| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY AUTO |
| name | TEXT | NOT NULL — user-friendly label ("Netflix", "Rent") |
| amount_minor_units | INTEGER | NOT NULL — fixed amount per occurrence |
| currency | TEXT | NOT NULL REFERENCES currencies(code) |
| category_id | INTEGER | NOT NULL REFERENCES categories(id) |
| account_id | INTEGER | NOT NULL REFERENCES accounts(id) |
| memo | TEXT | nullable — pre-filled on each generated item |
| frequency | TEXT | NOT NULL — `'daily'`, `'weekly'`, `'monthly'`, `'yearly'` |
| day_of_week | INTEGER | nullable — 0=Sun..6=Sat, required when frequency='weekly' |
| day_of_month | INTEGER | nullable — 1-31, required when frequency='monthly'. Clamps to last day of shorter months (e.g., Jan 31 → Feb 28) |
| month_of_year | INTEGER | nullable — 1-12, required when frequency='yearly' |
| is_active | BOOL | DEFAULT true — false = paused |
| is_archived | BOOL | DEFAULT false — true = soft-deleted |
| next_due_date | DATETIME | NOT NULL — denormalized for fast "which rules are due?" queries on app open |
| created_at | DATETIME | NOT NULL |
| updated_at | DATETIME | NOT NULL |

### Invariants

- `next_due_date` is recalculated after each generation: advance by the frequency interval
- Pausing sets `is_active = false`; resuming recalculates `next_due_date` from today (missed periods while paused are skipped — the rule starts generating from the resume date, not catching up on missed occurrences)
- A rule with pending transactions in `pending_transactions` can be paused but not hard-deleted (archive-on-delete pattern, same as categories/accounts). Soft-delete sets `is_archived = true` and `is_active = false`
- `amount_minor_units` is fixed per rule — the user edits the amount on the pending item if it varies (e.g., utility bills)
- **Edit propagation:** Edits to a rule (amount, category, account, memo, frequency, etc.) only affect future generations. Already-generated pending items are left untouched — the user can edit or reject them individually from the Pending Transactions screen
- `day_of_week` uses 0=Sunday, 6=Saturday (US convention). Note: Dart's `DateTime.weekday` uses 1=Monday..7=Sunday — the repository/DAO must map between conventions when calculating next due dates
- Month-end clamping: if `day_of_month = 31` and next month has 30 days, use 30. Feb 29/30/31 → Feb 28 (or 29 in leap year)
- **Transaction type is derived from category, not stored on the rule.** Same as `transactions` — the form's type toggle controls which categories are shown, but the rule stores only `category_id`. The type is derived from `categories.type` at generation time and at display time. This is consistent with the PRD's "no third type value" principle
- **Archived references rejected:** Creating or editing a rule with an archived category or account is rejected at the repository layer with a typed exception. The category picker and account selector in the form filter out archived entries (same as transaction form)
- **Frequency-conditional field validation:** The repository rejects inserts/updates where frequency='weekly' and `day_of_week` is null, or frequency='monthly' and `day_of_month` is null, or frequency='yearly' and (`month_of_year` is null or `day_of_month` is null). The form UI shows inline validation errors for missing required fields before save is enabled. Frequency='daily' requires no additional fields
- `next_due_date` is stored as a date-only value (midnight in device-local timezone). The generation engine truncates to date before comparison. This ensures the idempotency check `(recurring_rule_id, date)` is exact and not affected by time-of-day drift
- Archived rules are hidden from the management list but their existing pending items remain visible in the Pending Transactions screen
- Categories and accounts referenced by active recurring rules participate in the same archive/delete guards as transactions and shopping-list items: a category or account referenced by any active rule cannot be hard-deleted

### Relation to `pending_transactions`

The `pending_transactions` table (Phase 2 prerequisite, see Prerequisites section) provides `source = 'recurring'` and `recurring_rule_id` FK. The recurring generation engine inserts rows with these fields set. No additional schema changes to `pending_transactions` are needed beyond what the Phase 2 base migration already provides.

### Schema Migration

This feature's `recurring_rules` table is created as part of the Phase 2 schema migration (v3 → v4 per `PRD.md:498`), which also introduces `pending_transactions`, `wallet_addresses`, `exchange_rates`, and token rows in `currencies`. The migration section here covers only the `recurring_rules` table; the full v4 migration plan covers all Phase 2 tables together.

- Create `recurring_rules` table
- Add index on `recurring_rules(is_active, next_due_date)` for the "which rules are due?" query on app open
- Add index on `recurring_rules(is_archived)` for management list filtering
- Migration tested on both empty and seeded v3 databases

---

## Architecture — Use Case Pattern

Mirrors the wallet sync architecture from `PRD.md`. This feature introduces the `domain/` layer for the first time in this codebase. Future Phase 2 use cases (e.g., `wallet_sync_use_case.dart`, `approve_pending_transaction_use_case.dart`) follow the same `domain/` convention.

### Layer Boundaries

| Component | Layer | Responsibility |
|-----------|-------|---------------|
| `RecurringRuleDao` | Data/DAO | Thin SQL wrapper for `recurring_rules` table |
| `RecurringRulesRepository` | Data/Repository | SSOT for `recurring_rules`. Maps Drift rows → Freezed domain models. Enforces invariants (pause/delete guards, clamping) |
| `RecurringRule` | Data/Model | Freezed domain model |
| `RecurringGenerationUseCase` | Domain | Scans active rules, creates pending items, advances `next_due_date`. Coordinates `RecurringRulesRepository` + `PendingTransactionRepository` |
| `RecurringRulesController` | UI/Controller | Exposes management state + commands (create/edit/pause/resume/delete). Uses `StreamNotifier` for reactive list |
| `RecurringRulesScreen` | UI/Widget | Management list screen |
| `TransactionFormScreen` (reused) | UI/Widget | Creation/edit form with `RecurringRuleFormMode` |

### Generation Engine — `RecurringGenerationUseCase`

**Trigger:** On app open, after bootstrap completes. Called from `bootstrap.dart` as a side effect, same timing as wallet sync.

**Failure mode:** If `RecurringGenerationUseCase.execute()` throws during bootstrap (e.g., DB corruption, unexpected null), the error is caught and logged. The app continues normally — the user can still use all other features. Generation will retry on next app open. This prevents a recurring-rule issue from bricking the entire app.

**Startup performance:** Generation runs as a fire-and-forget async call (`unawaited`) from bootstrap — it does not block the first frame. The pending badge count on Home updates reactively when the generation completes and the `pending_transactions` stream emits.

**Flow:**

```
App open
  → RecurringGenerationUseCase.execute()
    → query recurring_rules WHERE is_active = true AND is_archived = false AND next_due_date <= today
    → for each due rule:
      → check: does pending_transactions already have a row with
        recurring_rule_id = rule.id AND date = rule.next_due_date?
        → skip if yes (idempotent — prevents duplicates on re-open)
      → insert into pending_transactions:
          source = 'recurring'
          recurring_rule_id = rule.id
          amount_minor_units = rule.amount_minor_units
          currency = rule.currency
          category_id = rule.category_id
          account_id = rule.account_id
          memo = rule.memo
          date = rule.next_due_date (date-only, midnight)
          fetched_at = now
      → advance rule.next_due_date by frequency interval:
          daily: +1 day
          weekly: +7 days
          monthly: same day next month (clamp to last day)
          yearly: same month/day next year (clamp for leap year)
      → update rule in DB
```

**Edge cases:**
- **Clamping:** If `day_of_month = 31` and next month has 30 days → use 30. Feb 29/30/31 → Feb 28 (or 29 in leap year)
- **Idempotency:** The `(recurring_rule_id, date)` check on `pending_transactions` prevents duplicate generation if the user opens the app multiple times on the same day. Both `next_due_date` and the pending item's `date` are date-only (midnight), so the comparison is exact regardless of time-of-day
- **Midnight boundary:** If the app opens at 23:59 and again at 00:01 (next day), the second open sees a new "today" and may generate the next occurrence if the rule is due. This is correct behavior — the idempotency guard prevents duplicates for the same date, not for different dates
- **Skipped periods:** If the user hasn't opened the app for 3 months, all missed monthly occurrences are generated (one pending item per missed month, each with its own date, in chronological order)
- **Paused rules:** Skipped — `is_active = false` rules are not queried
- **Archived rules:** Skipped — `is_archived = true` rules are not queried

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

- **List of rules** (excluding archived), each tile shows: name, amount + currency, frequency label (e.g., "Monthly on 15th"), next due date, active/paused indicator
- **Swipe actions:** swipe left → Pause/Resume toggle; swipe right → Archive (with 4-second undo snackbar, same pattern as Home and Shopping List). The archive happens when the timer expires; undo cancels it
- **Tap a rule** → opens the edit form (reused transaction form, pre-filled)
- **FAB** → opens the creation form (reused transaction form, empty)
- **Empty state:** "No recurring transactions" with CTA to create one

### Creation/Edit Form — `TransactionFormScreen` with `RecurringRuleFormMode`

The existing `TransactionFormScreen` is extended with a new `TransactionFormMode` subclass: `RecurringRuleFormMode`. This mode reuses the shared form sub-widgets (type toggle, amount keypad, category picker, account selector, currency selector, memo field) but swaps out the date-specific sections:

**What stays the same:**
- Expense/Income segmented control at top
- Calculator-style amount keypad (fixed bottom)
- Category picker (icon grid, filtered by selected type)
- Account selector with currency indicator
- Currency selector tile
- Memo field

**What changes in `RecurringRuleFormMode`:**
- **Name field** added below the type toggle (text input, required, placeholder: "Rule name")
- **Date picker is replaced by** a recurrence pattern section:
  - Frequency dropdown: Daily / Weekly / Monthly / Yearly
  - Conditional field based on frequency:
    - Weekly → day-of-week picker (Sun–Sat horizontal chips, single select)
    - Monthly → day-of-month picker (1–31 number input with validation)
    - Yearly → month picker (1–12 dropdown) + day-of-month input
    - Daily → no extra field
- **"Save" button label changes** to "Create Rule" (or "Update Rule" in edit mode)
- **"Add to shopping list" action is hidden**
- **Delete action** in edit mode archives the rule (same as swipe-archive on the list screen)

**Implementation approach:** `TransactionFormScreen` checks its `TransactionFormMode` in `build()`. When the mode is `RecurringRuleFormMode`, it renders the name field and recurrence section in place of the date picker. The shared sub-widgets (keypad, category picker, account selector) are unchanged. The controller's save command branches based on mode: `TransactionFormMode` → `TransactionRepository.save()`, `RecurringRuleFormMode` → `RecurringRulesRepository.insert()` or `.update()`.

### Pending Transactions Integration

Recurring pending items appear in the existing Pending Transactions screen (Phase 2 prerequisite) alongside blockchain items, grouped by source. Each recurring item shows: rule name, amount + currency, frequency label, due date. Same approve/reject flow as blockchain items — approve inserts into `transactions` and deletes the pending row; reject deletes the pending row only. Rejecting a recurring pending item does not affect the rule — the next app open will generate the next occurrence normally.

---

## Routing

New routes under Settings branch:

```
/settings/recurring              → RecurringRulesScreen (management list)
/settings/recurring/new          → TransactionFormScreen with RecurringRuleFormMode (modal push)
/settings/recurring/:id          → TransactionFormScreen with RecurringRuleFormMode (modal push, edit)
```

Same adaptive dialog treatment as `/settings/manage-accounts/:id` on ≥600dp.

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
    repositories/
      recurring_rules_repository.dart       # NEW — SSOT for recurring_rules
  domain/
    recurring_generation_use_case.dart      # NEW — scans rules, creates pending items
  features/
    recurring/
      recurring_rules_screen.dart           # NEW — management list
      recurring_rules_controller.dart       # NEW — list state + pause/resume/delete commands
      recurring_rules_state.dart            # NEW — Freezed state
      recurring_rules_providers.dart        # NEW — slice-local helper providers
```

Note: `domain/` is introduced for the first time by this feature. The `PendingTransactionRepository` and related data-layer files are part of the `pending_transactions` prerequisite (see Prerequisites section) and are not listed here.

---

## Changes to Existing Files

| File | Change |
|------|--------|
| `app_database.dart` | Add `RecurringRules` table + `RecurringRuleDao` to `@DriftDatabase` annotation |
| `repository_providers.dart` | Add `recurringRulesRepositoryProvider` |
| `bootstrap.dart` | Call `RecurringGenerationUseCase.execute()` after DB open |
| `router.dart` | Add `/settings/recurring`, `/settings/recurring/new`, `/settings/recurring/:id` routes |
| `settings_screen.dart` | Add "Recurring Transactions" tile |
| `transaction_form_screen.dart` | Add `RecurringRuleFormMode` branching (name field, recurrence section, save command) |
| `transaction_form_state.dart` | Add `RecurringRuleFormMode` to `TransactionFormMode` sealed union |
| `l10n/app_en.arb` | Add recurring-related strings |
| `l10n/app_zh_TW.arb` | Add recurring-related strings (Traditional Chinese) |
| `l10n/app_zh_CN.arb` | Add recurring-related strings (Simplified Chinese) |

---

## Testing Strategy

### Repository Tests (`test/unit/repositories/recurring_rules_repository.dart`)

- CRUD operations (insert, update, delete, getById)
- `next_due_date` calculation after each frequency (daily +1, weekly +7, monthly clamp, yearly leap-year clamp)
- Pause/resume: `is_active` toggle, `next_due_date` recalculation on resume
- Archive guard: cannot hard-delete a rule that has pending transactions; archive sets `is_archived = true` and `is_active = false`
- FK guard: category/account referenced by active rule participates in delete guard (cannot hard-delete)
- FK archive guard: archiving a category/account that is referenced by an active rule is allowed (same as transaction references), but the management screen shows an inline warning
- Archived reference guard: creating or editing a rule with an archived category or account is rejected at the repository layer
- Stream emissions on mutations

### Use Case Tests (`test/unit/use_cases/recurring_generation_use_case.dart`)

- Happy path: active rule with due date → pending transaction created, `next_due_date` advanced
- Idempotency: same rule, same due date → no duplicate pending item
- Skipped periods: 3 months of missed monthly rules → 3 pending items generated
- Paused rules skipped
- Archived rules skipped
- Multiple rules with different frequencies → all due items generated
- Edge cases: month-end clamping (Jan 31 → Feb 28, Aug 31 → Sep 30), leap year (Feb 29 → Feb 28 next year)
- Mock `RecurringRulesRepository` and `PendingTransactionRepository` via `mocktail`

### Controller Tests (`test/unit/controllers/recurring_rules_controller.dart`)

- State transitions: loading → data, loading → error, empty state
- Commands: pause, resume, archive (with undo), edit
- Mock repository via Riverpod `ProviderContainer` overrides

### Widget Tests (`test/widget/features/recurring/`)

- Management screen: rule list rendering, empty state, pause/resume toggle, archive undo snackbar
- Form: frequency selector shows correct conditional fields, name field required, save disabled without required fields
- Form validation: invalid dates (e.g., Feb 30, day 31 in 30-day month) show inline error, clamping behavior surfaced to user

### Integration Tests (`test/integration/recurring_transaction_test.dart`)

- Create rule → app reopen → pending item generated → approve → visible in Home
- Pause rule → app reopen → no new pending items
- Reject pending recurring item → removed from pending, no effect on rule
- Archive rule → no longer appears in management list, existing pending items remain

---

## Open Questions

None — all design decisions resolved during brainstorming.
