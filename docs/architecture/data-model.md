# Data Model Invariants

> Authoritative source: [`PRD.md` → *Database Schema*](../../PRD.md#database-schema).

Drift schema is at **v7** (v7 backfills the seeded `category.investment` row; `transactions.amount_formula` added in v6; `exchange_rates` added in v5; `recurring_rules` + `pending_transactions` introduced in v4). Snapshots live in `drift_schemas/`. **Never rewrite a merged migration in place** — add a new schema version instead. See [`testing.md`](./testing.md) for migration test rules.

## Invariants

These are easy to violate and expensive to retrofit.

- **Money is stored as integer minor units.** `amount_minor_units`, `opening_balance_minor_units`, etc. — never doubles. The scaling factor comes from `currencies.decimals` (2 for USD, 0 for JPY, 18 for ETH). All decimal formatting goes through `core/utils/money_formatter.dart` at the UI boundary only.
- **Exchange-rate cache rows** in `exchange_rates` are stored as positive `rate_scaled_e9` integers (`round(rate × 10^9)`), keyed by `(base_currency, quote_currency)`. The table stores forward rates only (foreign → default); treat them as advisory display data, **not** persisted money values.
- **Category `type` is immutable after first use.** Once a transaction references a category, its `type` (expense/income) is frozen — users needing the opposite type create a new category. Enforce this in `CategoryRepository`, not in the UI.
- **Seeded categories are identified by `l10n_key`, not by display name.** Renames write `custom_name` but keep `l10n_key` so locale changes do not duplicate or orphan rows. Users can rename any seeded category; auto-translation is not applied after a rename.
- **Archive-instead-of-delete** for any category or account that has transactions. Hard-delete is only allowed for unused custom rows.
- **Icons and colors are indirect.** `categories.icon` is a string key resolved via `core/utils/icon_registry.dart`; `categories.color` is an **index** into the append-only `core/utils/color_palette.dart`. Never store raw `IconData` symbols or ARGB ints in the DB — both break across Flutter/Material updates and across backup/restore.

## `pending_transactions` (universal staging table)

`pending_transactions` is a universal staging table for both blockchain and recurring sources, discriminated by `source`. Shared columns are always populated; source-specific columns (e.g. `tx_hash`, `recurring_rule_id`) are nullable.

- The **`recurring`** source shipped 2026-05-08 via `RecurringGenerationUseCase` (cold-start generation) + `PendingSection` on Home (inline approve / skip-once).
- The **`blockchain`** source is still Phase 3 / pending.

**Approve** = insert into `transactions` + delete from `pending_transactions` atomically (`Drift.transaction { _txRepo.save(); _dao.rejectRow() }`), preserving the original `currency` and `amount_minor_units`.

**Skip** rejects ONE occurrence (4-second undo window via `kUndoWindow`); the parent `recurring_rules` row is untouched and keeps generating future occurrences.

## Pagination Cap

MVP renders up to **10,000 transactions** via Drift streams + `ListView.builder` / slivers. This is a documented, accepted limit — don't preemptively add pagination in MVP, but don't claim the app scales past it either. Cursor pagination lands in Phase 2 (`TransactionRepository.watchPage`).
