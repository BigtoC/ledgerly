# Fortune City CSV Import — Design Spec

**Date:** 2026-10-30
**Status:** Approved for implementation. The user answered the open questions on 2026-10-30; see [Decisions](#decisions).
**PRD reference:** `PRD.md` § Phase 2: "[Pending] Fortune City CSV import"; § Security & Privacy: "Future CSV import/export must be explicit user actions with schema validation, size limits, malformed-row handling, formula escaping, and clear warnings…"
**Sample data:** `test/data/import_fortune_city_data.csv` (export from the Fortune City / 記帳城市 app)
**Depends on** (merged to `main` in #62):
- the `category.investment` expense category (en "Investment", zh_TW 理財, zh_CN 理财) and its schema v7 data-only migration;
- zh labels renamed to Fortune City's names: Food 食物, Drinks 飲品/饮品, Shopping 消費/消费, Housing 居家, Medical 醫藥/医药;
- `category.personal` retired (no longer seeded; v7 deletes it when unused, archives it otherwise).

---

## Summary

Add **Settings → Import from CSV**. The user picks a Fortune City CSV file. The app parses it, drops rows that already exist, matches each remaining row's Account and Category against existing rows and every locale's l10n labels, and shows a preview. In the preview the user resolves any account the app cannot match and can set the type of each category that will be created. On confirm, the app creates the missing account types, accounts and categories and inserts every transaction in **one Drift transaction**. It then shows a result summary.

No schema change is needed; the import runs on schema v7. It needs:

- one new `TransactionRepository` write path, because `save()` overwrites `createdAt`;
- one narrow read path that returns only the fields duplicate detection compares;
- two packages: `file_selector` and `csv`.

**Acceptance criterion:** on a freshly seeded install (en_US), importing the sample file produces exactly 105 new transactions.
- The only question the user must answer is about `Credit Card`.
- `Cash` maps to the seeded "Cash" account.
- `Investment` is shown as already decided, with a "New" badge: a new "Investment" account of type `accountType.investment`. The user can change it.
- Ten categories match built-in ones (食物, 交通, 飲品, 理財, 娛樂, 醫藥, 3C, 居家, 消費, 其他). 收入 rows are income: the one whose note is 薪資 lands in `category.income.salary`, the other nine in `category.income.other`. Three new custom categories are created (還款, 個人護理, 休閒), all expense unless the user toggles one.
- Each transaction's `date` is the start of its Recorded At day and its `createdAt` is Recorded At, both in device-local time. Its `updatedAt` is the import time.
- `23.6000003814697` HKD is stored as `2360` minor units.
- Importing the same file a second time reports 105 duplicates in the preview, asks no questions, keeps Import disabled, and inserts 0 rows.

---

## Goals

- A Settings entry that opens a file picker limited to CSV and plain-text files.
- Parse the Fortune City format: header `Account,Category,Amount,Currency,Recorded At,note,Account ID`.
- Resolve **accounts** by existing account name, then by account-type label in any locale. Ask the user about anything still unmatched.
- Resolve **categories** by l10n label in any locale or by an existing custom name. Create a custom category when nothing matches. Income rows (收入) go to Salary when their note is the Salary label, otherwise to Other income.
- Round amounts half-up on the decimal string and store them as integer minor units. Doubles are never used.
- Write `date = startOfDay(Recorded At)`, `createdAt = Recorded At` and `updatedAt = import write time`.
- Make the whole import atomic. Re-importing the same file must insert nothing.
- Report malformed rows by line number with a reason, without logging their contents.

## Non-goals

- **Other CSV dialects** (generic column mapping, other apps' exports, Excel-resaved Big5/UTF-16 files). The parser is Fortune City–specific. The column names are constants in one place.
- **CSV export.** This stays in PRD Phase 3.
- **Transfers and repayments as linked pairs.** 還款 rows are imported as ordinary single transactions in a plain category. Credit-card and transfer flows remain separate Phase 2 work.
- **Editing individual rows in the preview,** or remapping a to-be-created category onto an existing one. Near-miss labels were resolved by renaming the built-in zh labels instead (see [Decisions](#decisions)).
- **Undo after import.** The preview shows every account and category decision before anything is written, and atomicity means there is never a half-import to clean up. Imported rows can be deleted individually as usual. A batch undo is a possible follow-up.
- **Adjusting opening balances.** Imported history changes the balances of the accounts it lands in. The preview says so; it does not compensate.
- **Background or streaming import.** The file is capped at 10,000 rows and parsed in memory.

---

## Prerequisites

- `category.investment`, the zh label renames and the Personal retirement (merged to `main` in #62; schema v7).
- Add `file_selector` and `csv` to `pubspec.yaml`. See [Dependencies](#dependencies).

---

## User Flow

```
Settings ─▶ "Import from CSV" tile ─▶ /settings/import  (CsvImportScreen, modal route)
  [Idle]        intro text + privacy note + "Choose CSV file" button
     │ tap
     ▼
  system file picker (file_selector)  ── cancelled ──▶ back to Idle (no error)
     │ file chosen
     ▼
  [Parsing]     spinner; size check, UTF-8 decode, CSV parse, header check,
                per-row validation, currency lookup, rounding, duplicate check,
                matching
     │                         └── file-level error ──▶ [Failure] message + "Choose another file"
     ▼
  [Preview]
     • File name, rows to import, date range
     • Note: "Imported transactions change the balances of the accounts they go into."
     • Accounts      one row per distinct CSV Account value among the rows to import:
                       ✓ matched → account name (tap to change)
                       ✓ New → "Create account 'Investment' (Investment)" (tap to change)
                       ? needs a decision → choice sheet (see Account Resolution)
     • Categories    "Will use existing": list
                     "Will be created": list, each with an Expense/Income toggle (default Expense)
     • Duplicates    "N rows already exist and will be skipped"
     • Invalid rows  "M rows will be skipped" → expandable list: line # + reason
     • [Import N transactions] — disabled until every account has a resolution
                                 and N > 0 (N = 0 shows "Nothing new to import")
     │ tap
     ▼
  [Committing]  spinner; back navigation blocked (PopScope)
     │                         └── exception ──▶ [Failure] "Nothing was imported" + retry
     ▼
  [Done]        "Imported N transactions" · "Skipped D duplicates, M invalid rows"
                · "Created X accounts, Y categories" · [Done] pops to Settings
```

Every state change is driven by the controller. The screen only renders state and forwards taps, following the "no try/catch in widgets" rule in `layers.md`.

---

## CSV Format and Field Mapping

### Header

The parser matches header names after trimming. Matching is exact and case-sensitive, and column order does not matter.

- **Required:** `Account`, `Category`, `Amount`, `Currency`, `Recorded At`.
- **Optional:** `note` (missing → memo null), `Account ID` (always ignored).
- Extra columns are ignored.
- A missing required column is a **file-level error** that lists the missing names.

### Mapping

| CSV column    | DB target                                                                        | Rule                                                                                                                                                                                             |
|---------------|----------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Account`     | `transactions.account_id`                                                        | Resolved to an existing or newly created account. See [Account Resolution](#account-resolution). The CSV value is never stored verbatim except as the name of a created account or account type. |
| `Category`    | `transactions.category_id` (and therefore type)                                  | See [Category Resolution](#category-resolution). The type (expense or income) comes from the resolved category.                                                                                  |
| `Amount`      | `transactions.amount_minor_units`                                                | See [Amounts](#amounts-and-rounding). Half-up rounding on the decimal string, then scaled by `currencies.decimals`. Must be > 0 after rounding.                                                  |
| `Currency`    | `transactions.currency`                                                          | Trimmed and upper-cased, then it must exist in `currencies` (`CurrencyRepository.getByCode`). Otherwise the row is invalid.                                                                      |
| `Recorded At` | `transactions.created_at` (full minute), `transactions.date` (start of that day) | Parsed as device-local time. See [Dates](#dates-and-timestamps).                                                                                                                                 |
| —             | `transactions.updated_at`                                                        | Import write time: `insertImported` reads the repository clock once per call and uses that value for every row.                                                                                  |
| `note`        | `transactions.memo`                                                              | Stored verbatim (Unicode). A field that is empty or only whitespace becomes `null`. It is not evaluated or escaped. See [Privacy & Security](#privacy--security).                                |
| `Account ID`  | —                                                                                | Ignored, per the user's requirement.                                                                                                                                                             |
| —             | `transactions.amount_formula`                                                    | Always `null`.                                                                                                                                                                                   |

---

## Account Resolution

Accounts have no `l10n_key`; they are matched by `accounts.name`. Account **types** have l10n labels. The user's wording ("match the l10n", "new account types", "account id should match our existing account which matches the account field") reconciles as follows: a CSV Account value first tries to name an **account**, then falls back to an **account type**. Because `transactions.account_id` is NOT NULL, every CSV value must end up as an **account**, never just a type.

**Input:** only the distinct Account values of rows that will be inserted, meaning valid rows that are not duplicates (see [Duplicate Handling](#duplicate-handling)). Values that appear only in invalid or duplicate rows are not shown, so the import never asks about, or creates, an account that would receive no transactions.

**Normalization:** `trim()` + `toLowerCase()`. Only Latin letters fold; CJK text compares exactly. There is no Traditional/Simplified conversion. Both scripts' labels are indexed separately, so none is needed.

For each distinct CSV Account value, the first tier that applies wins:

| Tier | Condition                                                                                                                                                                    | Initial resolution                    | Shown as                                            |
|------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------|-----------------------------------------------------|
| 1    | Exactly one **active** account whose normalized `name` equals the value                                                                                                      | That account                          | ✓ matched, changeable                              |
| 1b   | More than one active account has that name                                                                                                                                   | none                                  | ? needs a decision. The options are those accounts. |
| 2    | Value equals an **account-type** label (`customName`, or the en / zh_TW / zh_CN label of its `l10nKey`) of a non-archived type, and exactly one active account has that type | That account                          | ✓ "matched by type", changeable                    |
| 2b   | Same as tier 2, but no active account of that type exists                                                                                                                    | "Create account '<value>' (type <T>)" | ✓ with a **New** badge, changeable                 |
| 2c   | Same as tier 2, but several active accounts of that type exist                                                                                                               | none                                  | ? needs a decision. The options are those accounts. |
| 3    | No match: a "new account type"                                                                                                                                               | none                                  | ? needs a decision                                  |

**`canCommit`** is true when every account entry has a non-null resolution and at least one row will be inserted. A tier 1, 2 or 2b initial resolution counts as decided; the user does not have to tap it. Only tiers 1b, 2c and 3 block Import. This matches the user's rule: the app asks only when the CSV names an account type that does not exist (tier 3) or when the choice is genuinely ambiguous (1b, 2c). Tier 2b creates an account under a type that already exists, and the **New** badge makes that visible.

**Archived accounts and types never auto-match.** This mirrors the transaction form, which hides archived accounts. The decision sheet does, however, list an archived account whose normalized name equals the value as an extra option labelled "(archived)", so a user who archived "Credit Card" after a first import can send new rows there instead of creating a second "Credit Card" type and account.

### The decision sheet

Opened from any account entry. The sheet is adaptive: a bottom sheet below 600dp and a dialog at 600dp and above, reusing the `manage_accounts_sheet.dart` pattern. It offers:

1. **Use an existing account**: a picker of active accounts, plus any archived account with the same normalized name, labelled "(archived)".
2. **Create account "<value>" of type <T>**: shown only for tiers 2, 2b and 2c, where a type matched.
3. **Create account type "<value>" and account "<value>"**: the user's "create a new account type that matches the csv". Always shown.

Rules for created rows:

- **Account type:**
  - `customName = <value>` (trimmed CSV text), `l10nKey = null`, `defaultCurrency = null`, `sortOrder = max + 1`.
  - Icon `wallet`, color `CategoryPaletteIndex.neutralVariant70`: the create-account-type defaults, which are also what the `accountType.cash` seed uses.
- **Account:**
  - `name = <value>`, `openingBalanceMinorUnits = 0`, `sortOrder = max + 1`, `icon`/`color` null (inherit from the type).
  - `currency` is the most frequent currency among the rows mapped to it. A tie goes to the user's default currency if it is tied, otherwise to the alphabetically first code.
- The same CSV value is never created twice within one import. If the user picks option 3 for a second CSV value whose name normalizes the same way, the two resolutions share one created type and account.

**Sample file on a fresh en_US install:**
- `Cash` → tier 1 → seeded account "Cash" (`kSeededCashAccountName`).
- `Investment` → tier 2b, because the type `accountType.investment` exists but has no account → ✓ New "Create account 'Investment' (Investment)". English "Investment" also labels `category.investment`, but account and category matching are separate, so this does not interact.
- `Credit Card` → tier 3 → the user must choose.

---

## Category Resolution

Categories carry `l10n_key` + `customName`. Matching uses **all** categories, both types and including archived ones, and every locale. The CSV mixes English account names with zh_TW category names, so matching must not depend on the current app locale.

**Input:** as for accounts, only the distinct Category values of rows that will be inserted.

**Label index** (built once per import; normalization as above): for each category row, the candidate labels are

- `customName`, when not blank;
- `categoryDisplayNameForKey(l10nKey, l)` for `l` in {en, zh_TW, zh_CN}, obtained via the synchronous `lookupAppLocalizations(Locale(...))`. Results equal to the raw key are skipped, because unknown keys fall through to the key. Bare `zh` is skipped because it returns English.

For each distinct CSV Category value, in order:

1. **Income marker.** The value equals the `transactionTypeIncome` or `categoriesSectionIncome` label in any locale ("Income", 收入). Fortune City writes its type label into the Category column for income rows, so these rows are **income**, and the category is chosen **per row from its note**:
   - note (trimmed, normalized) equals the `categoryIncomeSalary` label in any locale (薪資 / 工资 / Salary) or 薪资, the Simplified form of 薪資 → seeded `category.income.salary`;
   - any other note, or no note → seeded `category.income.other`.

   This is the user's rule ("if the income note is 薪資, put into salary, otherwise Other income"). It is the only per-row resolution; every other Category value resolves once per distinct value. Seeded categories cannot be deleted (`CategoryRepository.delete` throws for any row with an `l10nKey`), and an archived one is still matched, so both lookups always succeed. The preview lists the income marker under "Will use existing" with both targets and their row counts.
2. **Label match.** Collect the candidates whose labels include the value.
   - If all candidates have one type, pick within it: seeded (`l10nKey != null`) first, then active before archived, then lowest `sortOrder`, then lowest `id`.
   - If candidates exist in **both** types, prefer **expense** and apply the same tie-break. Example: English "Investment" hits `category.investment` (expense) and `category.income.investment` (income), so it resolves to expense.
   - Archived matches are used as they are, with no unarchive. Archive hides a category from pickers but preserves history, and imported rows are history. This also avoids a duplicate custom category with the same name.
3. **No match** → **create a custom category:**
   - `customName = <value>`, `l10nKey = null`, `type = expense` by default. The preview shows an Expense/Income toggle on each to-be-created category, because `CategoryTypeLockedException` stops the type changing once the category is used. See [D-3](#decisions).
   - `icon`/`color` use the category form's defaults, falling back to `category` / `CategoryPaletteIndex.neutralVariant50` (the `category.miscellaneous` seed). `sortOrder = max + 1`, `isArchived = false`.
   - Values that normalize the same way share one created category.

Re-importing is safe: on the second run, step 2 finds the categories created in the first run by `customName`.

**Sample file on a fresh install (14 distinct values, 105 rows):**

| CSV                  | Rows    | Resolution                                                                                         |
|----------------------|---------|----------------------------------------------------------------------------------------------------|
| 食物                 | 26      | `category.food` (zh_TW + zh_CN label)                                                              |
| 交通                 | 24      | `category.transportation` (zh_TW + zh_CN label)                                                    |
| 飲品                 | 11      | `category.drinks` (zh_TW label)                                                                    |
| 收入                 | 10      | income marker: note 薪資 (1 row) → `category.income.salary`; the other 9 → `category.income.other` |
| 理財                 | 8       | `category.investment` (zh_TW label)                                                                |
| 娛樂                 | 6       | `category.entertainment` (zh_TW label)                                                             |
| 醫藥                 | 5       | `category.medical` (zh_TW label)                                                                   |
| 3C                   | 3       | `category.threeC` (all locales)                                                                    |
| 居家                 | 2       | `category.housing` (zh_TW + zh_CN label)                                                           |
| 消費                 | 2       | `category.shopping` (zh_TW label)                                                                  |
| 其他                 | 1       | `category.other` (zh_TW + zh_CN label)                                                             |
| 還款, 個人護理, 休閒 | 3, 2, 2 | 3 new custom categories, **expense** unless toggled                                                |

Exact matching is enough for the sample because the built-in zh labels were renamed to Fortune City's names. There is no alias table.

---

## Amounts and Rounding

The sample's amounts carry float32 artifacts (`23.6000003814697`, `74.8000030517578`, `19869.76953125`).

1. **Syntax.** After `trim()`, the field must match `^\d+(\.\d+)?$`. Anything else makes the row invalid ("invalid amount"): a sign, grouping separators, exponent notation, an empty field or whitespace inside.
2. **Scale.** `scale = min(2, currency.decimals)`. HKD is 2, so the scale is 2, which is the user's "2 decimal points". JPY is 0, so the scale is 0. See [D-1](#decisions).
3. **Round half-up once,** on the digit string, to `scale`. Look at the first dropped digit; if it is ≥ 5, increment the kept digits with carry. Doubles are never used.
4. **Minor units.** Concatenate the integer part and the rounded fraction, then pad with zeros to `currency.decimals` digits. The result is a Dart `int`. **Overflow guard:** before `int.parse`, strip leading zeros from the minor-units digit string (after any carry). The row is invalid ("invalid amount") when that string is longer than 19 digits, or is 19 digits and compares greater than `'9223372036854775807'` (2^63 − 1). This is a pure string comparison. It matters for 18-decimal currencies (`data-model.md` names ETH): `10.5` would be 1.05 × 10^19 minor units, and Dart's native `int` would wrap silently.
5. **Zero after rounding** (for example `0.004`) makes the row invalid ("amount must be greater than 0"). This matches the transaction form's `amountMinorUnits > 0` rule. For a high-decimal token, amounts below 0.005 therefore become row errors. Fortune City exports fiat amounts, so this is accepted and documented, not specially handled.

Examples (HKD, decimals 2): `23.6000003814697 → 2360`, `74.8000030517578 → 7480`, `19869.76953125 → 1986977`, `483.049987792969 → 48305`, `4000 → 400000`, `14.61 → 1461`. JPY (decimals 0): `1234.5 → 1235`.

The helper is a pure function. `MoneyFormatter.parseToMinorUnits` is **not** reused: it is locale-sensitive and throws when there are more fractional digits than `currency.decimals`.

---

## Currency Handling

- The value is trimmed and upper-cased, then looked up once per distinct code with `CurrencyRepository.getByCode`.
- A code not in `currencies` makes every row with that code invalid ("unknown currency XXX"). The import never creates currencies, because `currencies.decimals` cannot be inferred from a CSV.
- No conversion happens. The transaction keeps its CSV currency even when the resolved account has a different currency, which the data model already allows (`transactions.currency` is independent of `accounts.currency`).
- **FX refresh.** After a successful commit, the controller resolves the default currency the way `TransactionFormController.save()` does: `ref.read(defaultCurrencyProvider).value ?? ref.read(initialDefaultCurrencyProvider)`. If any imported currency differs from it, the controller calls `unawaited(exchangeRateRepository.refreshAll(defaultCurrency))` **once**. The form calls `fetchRate(code, default)` for its single currency; an import can bring several currencies, so one `refreshAll` covers them all. It is never called per row.

---

## Dates and Timestamps

- **Format:** `yyyy/M/d H:mm` with optional `:ss`. Leading zeros are optional, `/` is the separator, and a single space separates date and time. The regex is `^(\d{4})/(\d{1,2})/(\d{1,2}) (\d{1,2}):(\d{2})(?::(\d{2}))?$`.
- **Validation:** build `DateTime.utc(y, M, d, H, m, s)` and require that its fields round-trip. This rejects out-of-range values such as `2026/02/30` or `25:00` ("invalid date"). UTC has no DST, so the check never rejects a valid wall-clock time.
- **Timezone:** the CSV has none, so values are **device-local**: after validation, `recordedAt = DateTime(y, M, d, H, m, s)`. A local time inside a DST gap (for example 02:30 on a spring-forward day in the US or EU) is accepted and shifted forward by Dart's `DateTime` normalization. This is documented, not tested; Dart cannot inject a timezone in a unit test, and Hong Kong, the sample's region, has no DST.
- **Columns:**
  - `transactions.date = DateHelpers.startOfDay(recordedAt)`. Every other write path stores midnight in `date` (the transaction form normalizes in its constructor, `setDate` and `_today()`; `date_field.dart` does the same). Home, search, charts and balances filter and group on `date`, so the history lands on the right days.
  - `transactions.created_at = recordedAt`, with minute (or second) precision, which is exactly the user's "Recorded At matches the createdAt field". The transaction form and `save()` preserve a stored `createdAt` on edit, so the value survives later edits.
  - `transactions.updated_at` = the repository clock, read once per `insertImported` call.
- Drift stores `DateTime` as unix seconds, so both values round-trip exactly.
- Future dates are accepted, since the transaction form allows them.

This is a deliberate, documented exception to the rule "on insert both timestamps are set to now" (PRD § transactions notes, `transaction_repository.dart` header, `data-model.md`). Those three places are updated in the same commit that adds the new repository method.

**Insert order.** Every imported row shares one `updatedAt`. `watchRecentMemosByCategory` orders by `updated_at DESC, id DESC`, and Home orders a day by `date DESC, id DESC`. The sample file is newest-first, so inserting in file order would give the oldest rows the highest ids: 2022 memos would top the memo suggestions, and rows within a day would show oldest first. The use case therefore sorts the rows by `(createdAt ASC, line DESC)` before calling `insertImported`, so id order follows time order. `line DESC` keeps same-minute rows in true order for a newest-first export.

---

## Duplicate Handling

Confirmed by the user ([D-5](#decisions)).

The CSV has no stable row IDs. A duplicate key must not depend on anything the user decides in the preview or can change later, otherwise a different account choice, an archived account, a renamed category or a toggled type would make every row look new and silently double the history. The key therefore uses only values that come from the CSV row itself:

`(createdAt (unix seconds), amountMinorUnits, currency, memo ?? '')`

- **No `accountId` or `categoryId`.** Resolutions, archiving and renames cannot affect the result.
- **`createdAt`, not `date`.** The transaction form preserves `createdAt` when the user edits an imported row, including its date, account or category, so the row still counts as already imported. Hand-entered transactions get `createdAt` = the save time with seconds, so they almost never collide with an imported minute.

Dedup is **multiset-based**: for each key, `toInsert = max(0, countInFile − countInDb)`.

- Identical rows inside one file are kept. Two identical coffees in the same minute are legitimate.
- Re-importing the same file inserts 0 rows.
- Importing a later, longer export inserts only the new rows.

**When it runs.** Dedup runs during load, **before** matching, over every valid row. Only the rows left over (the "rows to import") feed account and category matching. This is why a re-import asks no questions. Because the key ignores resolutions, the duplicate count and the confirm count never change while the user edits the preview. The commit **recomputes** dedup inside its transaction, which is authoritative, and the Done screen reports the commit's numbers. If the recount leaves a to-be-created account, type or category with no rows, the commit does not create it.

**Read path.** `TransactionRepository.getImportSignatures(DateTime start, DateTime endInclusive)` returns only `({DateTime createdAt, int amountMinorUnits, String currencyCode, String? memo})` records for transactions whose `created_at` lies in the valid rows' range. It is backed by a narrow DAO select, not full `Transaction` domain objects, because the sample alone spans four years.

**Known limitations** (documented in the spec and the PR):

- If the device timezone changes between two imports, the same Recorded At maps to a different unix second, and the rows import again.
- If the user edits the amount or memo of an imported row, a re-import adds the original row again.
- A schema-level `import_key` column (v8) would remove both limitations. It is not added, to keep the import free of schema changes.

---

## Error Handling

**File-level errors** stop the import. The state becomes `CsvImportState.failure(kind)` and nothing is written.

| Kind                    | Trigger                                                                                                                                                                                                                                                                                                                      |
|-------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `tooLarge`              | File > **5 MB** by `XFile.length()`. This is a parse guard, not a memory guard: on Android, `file_selector_android` has already read the whole file into memory (and copied it into the app cache) before Dart receives the `XFile`.                                                                                         |
| `notUtf8`               | `utf8.decode(bytes, allowMalformed: false)` throws.                                                                                                                                                                                                                                                                          |
| `empty`                 | No header, or no data rows after skipping blank lines.                                                                                                                                                                                                                                                                       |
| `missingColumns(names)` | Required header missing.                                                                                                                                                                                                                                                                                                     |
| `tooManyRows(max)`      | More than **10,000** data rows. This matches the 10k pagination cap in `data-model.md`; the file is rejected rather than silently truncated.                                                                                                                                                                                 |
| `parse`                 | The decoded text contains an odd number of `"` characters. `csv` 8.0.0 never throws: an unterminated quote silently swallows the rest of the file into one field. In well-formed RFC 4180 text every quote is paired (opening/closing, or `""`), so an odd count always means a broken file. The check runs before decoding. |
| `commitFailed`          | Any exception during commit. The Drift transaction rolls back and "Nothing was imported" is shown.                                                                                                                                                                                                                           |

**Row-level errors** skip only that row. Each is recorded as `CsvRowError(lineNumber, reason)`, where `lineNumber` is the 1-based physical line in the file, so the header is line 1.

| Reason                           | Trigger                                                          |
|----------------------------------|------------------------------------------------------------------|
| `columnCount`                    | The row has fewer fields than the highest required column index. |
| `emptyAccount` / `emptyCategory` | Blank after trim.                                                |
| `invalidAmount` / `zeroAmount`   | See [Amounts](#amounts-and-rounding).                            |
| `unknownCurrency`                | See [Currency](#currency-handling).                              |
| `invalidDate`                    | See [Dates](#dates-and-timestamps).                              |

**Parsing details:**

- The decoder is configured as `Csv(fieldDelimiter: ',', autoDetect: false, skipEmptyLines: false, dynamicTyping: false)`, so amounts stay strings and empty lines stay visible for line counting. The decoder strips a leading BOM itself, so the parser does not strip it again.
- `\r\n` and `\r` are normalized to `\n` before the quote check and decoding.
- `csv` returns plain rows with no positions, so the parser computes line numbers itself: the header is line 1, and `line(i + 1) = line(i) + 1 + (number of '\n' inside row i's fields)`. A quoted memo containing a newline therefore shifts the following rows correctly.
- Rows whose fields are all empty are skipped silently by the parser and are not errors.
- Quoted fields (RFC 4180) are supported, including commas, `""` and newlines inside quotes.
- The preview shows invalid rows as **line number + localized reason only**. Field values are not shown, which keeps the list free of memos and amounts.
- If every row is invalid or a duplicate, the Import button is disabled and the preview says "Nothing new to import".

---

## Architecture

### Layer placement

| Layer          | File                                                                                                             | Purpose                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|----------------|------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Service        | `lib/data/services/csv_file_service.dart`                                                                        | Wraps `file_selector.openFile`. Returns `({String name, Uint8List bytes})?` (null = cancelled) or throws `CsvFileTooLargeException` (defined in the same file; services may not import models). After reading the bytes it deletes `XFile.path` when that path lies inside `getTemporaryDirectory()`, which is where `file_selector_android` copies the picked file. This avoids leaving a copy of financial data in the app cache. Deletion failures are ignored. It knows nothing about the CSV format.                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| Core           | `lib/core/utils/decimal_rounding.dart`                                                                           | `int decimalStringToMinorUnits(String digits, {required int scale, required int decimals})`: pure half-up rounding, scaling and the 2^63 − 1 overflow guard. Throws `FormatException` on bad syntax or overflow.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Core           | `lib/core/utils/fortune_city_csv_parser.dart`                                                                    | `FortuneCityCsvParseResult parseFortuneCityCsv(Uint8List bytes)`. Covers UTF-8, line endings, the quote-parity check, `csv` decode, line numbering, header mapping, per-row syntax checks and date parsing. It outputs `ParsedCsvRow{line, account, category, amountText, currencyCode, recordedAt, memo}` plus row errors, or throws `CsvFileException(kind)`. It does not look up currencies or round; the use case does both, because they need the DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| Model          | `lib/data/models/csv_import.dart`                                                                                | Freezed types and exceptions shared by core, the use case, the controller and the state: `CsvFileException` + `CsvFileErrorKind`, `CsvImportRow` (rounded, currency-resolved), `CsvRowError`, `CsvRowErrorReason`, the sealed `AccountResolution` (`existing(accountId)` / `createAccount(name, accountTypeId, currencyCode)` / `createTypeAndAccount(name, currencyCode)`), the sealed `CategoryResolution` (`existing(categoryId)` / `create(name, type)` / `incomeByNote(salaryCategoryId, otherCategoryId)`, where the use case picks one of the two ids per row from the note, using the Salary labels the matcher passes in the plan), `CsvLoadResult`, `CsvImportPlan` and `CsvImportResult`.                                                                                                                                                                                                                                                    |
| Repository     | `lib/data/repositories/transaction_repository.dart` (extend)                                                     | `Future<int> insertImported(List<Transaction> txs)`: reads `_clock()` **once**, then inserts every row in the given order with `createdAt = tx.createdAt`, `updatedAt` = that value and `amountFormula = null`. It uses a Drift `batch` inside `_db.transaction`; when the caller already holds a transaction, Drift runs it as a savepoint. It pre-checks each distinct currency (`CurrencyNotFoundException`). Also `getImportSignatures(start, endInclusive)`, backed by a new narrow DAO query (see [Duplicate Handling](#duplicate-handling)).                                                                                                                                                                                                                                                                                                                                                                                                     |
| Use case       | `lib/data/use_cases/csv_import_use_case.dart`                                                                    | Constructor takes the transaction, category, account, account-type and currency repositories plus `AppDatabase`, as `RecurringGenerationUseCase` does. `Future<CsvLoadResult?> pickAndLoad()`: service, then parser, then currency lookup, rounding and dedup. It returns the rows to import, the duplicate count, the row errors and the file name, or null when the user cancels. It catches `CsvFileTooLargeException` and rethrows `CsvFileException(CsvFileErrorKind.tooLarge)`, so callers see one domain exception type. `Future<CsvImportResult> commit(CsvImportPlan)`: one `db.transaction` that recomputes dedup, then creates account types, then accounts, then categories (via the existing repositories' `save`, skipping any with no remaining rows), sorts the rows and calls `insertImported`. No `clock` parameter; `updatedAt` comes from the repository clock.                                                                     |
| Providers      | `lib/app/providers/repository_providers.dart` (extend)                                                           | `csvFileServiceProvider`, `csvImportUseCaseProvider`, following `recurringGenerationUseCase`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| Feature helper | `lib/features/settings/csv_import/csv_import_matcher.dart`                                                       | Pure matching ([Account](#account-resolution) and [Category](#category-resolution) resolution). Inputs: distinct CSV values from the rows to import, the domain lists of `Category`, `Account` and `AccountType`, and an injected `List<AppLocalizations>` label set. Outputs initial resolutions, tier info and the sheet's option lists. The catch-all layer rule applies, so it may import `l10n` and the `widgets/*_display.dart` helpers but not repositories.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Feature helper | `lib/features/accounts/widgets/account_type_display.dart` (extend)                                               | Extract `accountTypeDisplayNameForKey(String key, AppLocalizations)`, mirroring `categoryDisplayNameForKey`. `accountTypeDisplayName` delegates to it, so behaviour is unchanged.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| Controller     | `lib/features/settings/csv_import/csv_import_controller.dart`                                                    | `@Riverpod(dependencies: [csvImportUseCase, categoryRepository, accountRepository, accountTypeRepository, exchangeRateRepository, defaultCurrency, initialDefaultCurrency])`. Synchronous notifier: `CsvImportState build() => const CsvImportState.idle()`. **Not** `keepAlive` (the screen scopes it). Commands: `pickFile()`, `setAccountResolution(String csvValue, AccountResolution)`, `setNewCategoryType(String csvValue, CategoryType)`, `commit()`, `reset()`. The two setters only update the plan and recompute `canCommit`; counts do not change (see [Duplicate Handling](#duplicate-handling)). Builds the label set with `lookupAppLocalizations` for en, zh_TW and zh_CN, and reads repositories with `.first` on their `watchAll(includeArchived: true)` streams once per load. Catches `CsvFileException` for load failures and any exception from `commit` as `commitFailed`; it never imports `data/services/`. No `BuildContext`. |
| State          | `lib/features/settings/csv_import/csv_import_state.dart`                                                         | Freezed sealed: `idle`, `loading`, `preview(...)`, `committing`, `done(CsvImportResult)`, `failure(CsvFileErrorKind)`. `preview` carries the file name, rows to import, row errors, the account entries (CSV value, row count, tier, current resolution, isNew, options), the category entries (CSV value, resolution, type, isNew), `duplicateCount` and `canCommit`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| Screen         | `lib/features/settings/csv_import/csv_import_screen.dart`                                                        | A `CustomScrollView` with slivers. The invalid-row list uses `SliverList.builder`. Wrapped in `PopScope(canPop: state is! committing)`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Widgets        | `lib/features/settings/csv_import/widgets/csv_account_resolution_sheet.dart`, `csv_import_preview_sections.dart` | The decision sheet (adaptive at 600dp) and the preview sections, including the per-category type toggle.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| Route          | `lib/app/router.dart`                                                                                            | A `GoRoute(path: 'import', parentNavigatorKey: _rootNavigatorKey, pageBuilder: … _modalPage(state, const _AdaptiveFormRoute(child: CsvImportScreen())))` under `/settings`, copying `recurring/new`. Add `CsvImportController` to the `router` provider's `dependencies` list and regenerate `router.g.dart`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| Settings entry | `lib/features/settings/settings_screen.dart`                                                                     | A `ListTile(key: ValueKey('settingsImportCsvTile'), title: l10n.settingsImportCsvTile, trailing: chevron, onTap: push('/settings/import'))` appended to the **General** section after the recurring tile. No new section, no new `@Dependencies`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |

**Why a use case, not a new repository:** the commit coordinates four repositories inside one `db.transaction`, which is exactly the role `RecurringGenerationUseCase` already plays. A controller may import use cases, and the use case owns the service call and translates its exception (`layers.md`: use cases translate failures into domain types), so the controller never touches `data/services/`.

**Why the matcher lives in `features/`:** label matching needs `AppLocalizations` and the `l10n_key → label` switch helpers, which live in the feature layer. The data layer stays locale-free, as `layers.md` requires.

**Dispose safety:** `commit()` is not cancellable once it starts; the Drift transaction completes or rolls back. The screen blocks pop during `committing`. The controller also checks `ref.mounted` before every post-`await` state write.

**Performance:** the parser is a pure function of the bytes and runs on the main isolate. At the 10,000-row cap it is expected to be well under a frame budget per thousand rows. Per the AGENTS.md performance rules, moving it to `Isolate.run` waits for a profile-mode measurement that shows jank.

### Data flow

```
CsvImportScreen ──tap──▶ CsvImportController.pickFile()
  ▶ csvImportUseCase.pickAndLoad()
      ▶ CsvFileService.pick()                      (file_selector; size cap; deletes cache copy)
        └ CsvFileTooLargeException → CsvFileException(tooLarge)
      ▶ parseFortuneCityCsv(bytes)                 (core; UTF-8/quotes/csv/lines/header/rows)
      ▶ CurrencyRepository.getByCode × distinct    (unknownCurrency rows → errors)
      ▶ decimalStringToMinorUnits per row          (core)
      ▶ TransactionRepository.getImportSignatures  (multiset dedup)
  ◀ CsvLoadResult(rowsToImport, duplicateCount, errors, fileName)
  ▶ repos.watchAll(includeArchived: true).first     (categories, accounts, types)
  ▶ CsvImportMatcher.resolve(rowsToImport, …, labelSets)   (feature; pure)
  ⇒ state = preview

user edits ─▶ setAccountResolution / setNewCategoryType ⇒ preview(canCommit recalculated)

tap Import ─▶ commit()
  ⇒ state = committing
  ▶ csvImportUseCase.commit(plan)
      db.transaction {
        recompute dedup via getImportSignatures
        AccountTypeRepository.save × new types     (only those with rows left)
        AccountRepository.save × new accounts      (only those with rows left)
        CategoryRepository.save × new categories   (only those with rows left)
        sort rows by (createdAt ASC, line DESC)
        TransactionRepository.insertImported(rows)
      }
  ▶ if any currency ≠ default: unawaited(exchangeRateRepository.refreshAll(default))
  ⇒ state = done(result)
```

---

## Dependencies

| Package         | Version  | Why                                                       | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
|-----------------|----------|-----------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `file_selector` | `^1.1.0` | Pick the CSV file through the system picker.              | First-party (flutter.dev). iOS uses Swift Package Manager (`file_selector_ios` ships `Package.swift`), so no CocoaPods and the `ios-nightly.yml` no-Podfile check stays green. Android adds no permissions or `<queries>`. No `Info.plist` keys. Ships no fonts or assets. Type group: `XTypeGroup(label: 'CSV', extensions: ['csv'], mimeTypes: ['text/csv', 'text/comma-separated-values', 'text/plain', 'application/vnd.ms-excel'], uniformTypeIdentifiers: ['public.comma-separated-values-text', 'public.plain-text'])`. Every iOS type group must have UTIs. Requires Flutter ≥ 3.47.0, which the repo already meets. |
| `csv`           | `^8.0.0` | RFC 4180 decoding (quoted memos with commas or newlines). | Pure Dart with no dependencies. SDK `^3.10.1` ≤ the repo's `^3.13.0`. Configuration as in [Error Handling](#error-handling). It never throws on malformed input, hence the parser's own quote-parity check. PRD lists `csv` under Phase 3, so move it to Phase 2 in the PRD dependency table.                                                                                                                                                                                                                                                                                                                                |

`path_provider` (already a direct dependency) supplies `getTemporaryDirectory()` for the cache-copy cleanup.

Rejected: `file_picker`. It adds four Android `<queries>` intents, `androidx.core`/`core-ktx`/`lifecycle` and a fast release cadence (13.3.0 is days old). A hand-rolled parser is about 50 lines but fragile on quoted memos, and the PRD already names `csv`.

After adding the packages: commit `pubspec.lock`, run `flutter build apk --analyze-size` and note the delta in the PR, and run the iOS debug build (CI `ios-nightly.yml` runs on `pubspec.*` changes).

---

## Localization

Add each key to `l10n/app_en.arb` (with an `@key` description), `app_zh_TW.arb` and `app_zh_CN.arb`. **Do not** touch `app_zh.arb`, which must contain only `appTitle`. Then regenerate `lib/l10n/`.

`test/unit/l10n/arb_audit_test.dart` compares `app_en.arb` against the exact set `_expectedEnKeys` and fails on any key it does not list. Commit 9 therefore adds every key below to `_expectedEnKeys` under a `// CSV import.` comment block.

| Key                                                           | en                                                                      | zh_TW                                          | zh_CN                                          |
|---------------------------------------------------------------|-------------------------------------------------------------------------|------------------------------------------------|------------------------------------------------|
| `settingsImportCsvTile`                                       | Import from CSV                                                         | 從 CSV 匯入                                    | 从 CSV 导入                                    |
| `csvImportTitle`                                              | Import from CSV                                                         | 從 CSV 匯入                                    | 从 CSV 导入                                    |
| `csvImportIntro`                                              | Import transactions exported from Fortune City.                         | 匯入從記帳城市匯出的交易。                     | 导入从记账城市导出的交易。                     |
| `csvImportPrivacyNote`                                        | The file is read on this device only. Nothing is uploaded.              | 檔案只會在此裝置上讀取，不會上傳。             | 文件只会在此设备上读取，不会上传。             |
| `csvImportChooseFile`                                         | Choose CSV file                                                         | 選擇 CSV 檔案                                  | 选择 CSV 文件                                  |
| `csvImportReading`                                            | Reading file…                                                           | 正在讀取檔案…                                  | 正在读取文件…                                  |
| `csvImportErrorTooLarge`                                      | This file is larger than 5 MB.                                          | 檔案超過 5 MB。                                | 文件超过 5 MB。                                |
| `csvImportErrorNotUtf8`                                       | This file is not UTF-8 text.                                            | 此檔案不是 UTF-8 文字。                        | 此文件不是 UTF-8 文本。                        |
| `csvImportErrorEmpty`                                         | This file has no transactions.                                          | 此檔案沒有任何交易。                           | 此文件没有任何交易。                           |
| `csvImportErrorMissingColumns` (`{columns}`)                  | Missing columns: {columns}                                              | 缺少欄位：{columns}                            | 缺少列：{columns}                              |
| `csvImportErrorTooManyRows` (`{max}` int)                     | This file has more than {max} rows.                                     | 檔案超過 {max} 列。                            | 文件超过 {max} 行。                            |
| `csvImportErrorParse`                                         | This file could not be read as CSV.                                     | 無法以 CSV 格式讀取此檔案。                    | 无法以 CSV 格式读取此文件。                    |
| `csvImportErrorCommit`                                        | Import failed. Nothing was imported.                                    | 匯入失敗，未匯入任何資料。                     | 导入失败，未导入任何数据。                     |
| `csvImportChooseAnother`                                      | Choose another file                                                     | 選擇其他檔案                                   | 选择其他文件                                   |
| `csvImportBalanceNote`                                        | Imported transactions change the balances of the accounts they go into. | 匯入的交易會改變所屬帳戶的餘額。               | 导入的交易会改变所属账户的余额。               |
| `csvImportSectionAccounts`                                    | Accounts                                                                | 帳戶                                           | 账户                                           |
| `csvImportSectionCategories`                                  | Categories                                                              | 類別                                           | 类别                                           |
| `csvImportSectionSkipped`                                     | Skipped rows                                                            | 略過的列                                       | 跳过的行                                       |
| `csvImportRowCount` (plural `{count}`)                        | {count} transactions                                                    | {count} 筆交易                                 | {count} 笔交易                                 |
| `csvImportAccountNeedsChoice`                                 | Choose where these go                                                   | 請選擇匯入位置                                 | 请选择导入位置                                 |
| `csvImportAccountMatchedByType`                               | Matched by account type                                                 | 依帳戶類型配對                                 | 按账户类型匹配                                 |
| `csvImportNewBadge`                                           | New                                                                     | 新增                                           | 新建                                           |
| `csvImportAccountUseExisting`                                 | Use an existing account                                                 | 使用現有帳戶                                   | 使用现有账户                                   |
| `csvImportAccountArchived` (`{name}`)                         | {name} (archived)                                                       | {name}（已封存）                               | {name}（已归档）                               |
| `csvImportAccountCreate` (`{name}`, `{type}`)                 | Create account "{name}" ({type})                                        | 建立帳戶「{name}」（{type}）                   | 创建账户“{name}”（{type}）                     |
| `csvImportAccountCreateWithType` (`{name}`)                   | Create account type and account "{name}"                                | 建立帳戶類型及帳戶「{name}」                   | 创建账户类型及账户“{name}”                     |
| `csvImportCategoriesExisting`                                 | Will use existing                                                       | 使用現有類別                                   | 使用现有类别                                   |
| `csvImportCategoriesNew`                                      | Will be created                                                         | 將會建立                                       | 将会创建                                       |
| `csvImportDuplicates` (plural `{count}`)                      | {count} rows already exist and will be skipped                          | {count} 筆已存在，將略過                       | {count} 笔已存在，将跳过                       |
| `csvImportInvalidRows` (plural `{count}`)                     | {count} invalid rows will be skipped                                    | {count} 筆無效資料將略過                       | {count} 笔无效数据将跳过                       |
| `csvImportNothingToImport`                                    | Nothing new to import                                                   | 沒有新資料可匯入                               | 没有新数据可导入                               |
| `csvImportRowErrorLine` (`{line}` int, `{reason}`)            | Line {line}: {reason}                                                   | 第 {line} 行：{reason}                         | 第 {line} 行：{reason}                         |
| `csvImportReasonColumnCount`                                  | missing fields                                                          | 欄位不足                                       | 字段不足                                       |
| `csvImportReasonEmptyAccount`                                 | empty account                                                           | 帳戶為空                                       | 账户为空                                       |
| `csvImportReasonEmptyCategory`                                | empty category                                                          | 類別為空                                       | 类别为空                                       |
| `csvImportReasonInvalidAmount`                                | invalid amount                                                          | 金額無效                                       | 金额无效                                       |
| `csvImportReasonZeroAmount`                                   | amount must be greater than 0                                           | 金額必須大於 0                                 | 金额必须大于 0                                 |
| `csvImportReasonUnknownCurrency` (`{code}`)                   | unknown currency {code}                                                 | 不支援的貨幣 {code}                            | 不支持的货币 {code}                            |
| `csvImportReasonInvalidDate`                                  | invalid date                                                            | 日期無效                                       | 日期无效                                       |
| `csvImportConfirm` (plural `{count}`)                         | Import {count} transactions                                             | 匯入 {count} 筆交易                            | 导入 {count} 笔交易                            |
| `csvImportImporting`                                          | Importing…                                                              | 正在匯入…                                      | 正在导入…                                      |
| `csvImportDoneTitle`                                          | Import complete                                                         | 匯入完成                                       | 导入完成                                       |
| `csvImportDoneImported` (plural `{count}`)                    | Imported {count} transactions                                           | 已匯入 {count} 筆交易                          | 已导入 {count} 笔交易                          |
| `csvImportDoneCreated` (`{accounts}` int, `{categories}` int) | Created {accounts} accounts and {categories} categories                 | 已建立 {accounts} 個帳戶及 {categories} 個類別 | 已创建 {accounts} 个账户及 {categories} 个类别 |
| `csvImportDone`                                               | Done                                                                    | 完成                                           | 完成                                           |

Existing keys are reused where they fit: `transactionTypeExpense` / `transactionTypeIncome` for the category type toggle, `accountTypeDisplayName` for `{type}`, and the existing cancel strings.

---

## Privacy & Security

- **Explicit action only.** Import starts only from the Settings tile and the picker. There is no file watching and no share-intent handler.
- **No logging of financial data.** CSV contents, memos, amounts, account names, category names, currency sets and file names are never logged. Failures log `${e.runtimeType}` only, and there are no `debugPrint` traces. The sample file contains a real person's name in memos.
- **Nothing leaves the device** except the existing currency-pair-only FX refresh.
- **No stray copies.** `file_selector_android` copies the picked file into the app cache directory. `CsvFileService` deletes that copy after reading it (see [Architecture](#architecture)).
- **Formula injection:** memos starting with `=`, `+`, `-` or `@` are stored as plain text and never evaluated. Escaping is an **export** concern, deferred to the CSV export work. This satisfies the PRD's "formula escaping" item for the import direction.
- **Size limits:** 5 MB and 10,000 rows, rejected after the platform has read the file and before parsing. They bound parse time and preview size, not peak memory on Android.
- **Schema validation:** required headers, quote parity, strict amount, date and currency validation, and per-row errors.

---

## Testing Plan

TDD per AGENTS.md: write each test first and watch it fail.

**Unit — core** (`test/unit/utils/`)
- `decimal_rounding_test.dart`:
  - half-up cases: `23.6000003814697 → 2360`, `74.8000030517578 → 7480`, `19869.76953125 → 1986977`, `483.049987792969 → 48305`, `0.005 → 1`, `0.004 → 0`, carry `9.995 → 1000`, `99.999 → 10000`;
  - integers;
  - JPY (scale 0, decimals 0): `1234.5 → 1235`;
  - a currency with decimals 3 (scale 2, padded);
  - a synthetic 18-decimal currency: `1.5 → 1500000000000000000` and `9.22 → 9220000000000000000` are accepted; `9.23` (> 2^63 − 1) and `10.5` throw; `9.225` throws because the check runs after the carry to `9.23`;
  - rejects `-1`, `1,000`, `1e5`, `''`, `' 1 2'`.
- `fortune_city_csv_parser_test.dart`:
  - **using `test/data/import_fortune_city_data.csv`**: 105 rows, 0 errors; account counts Cash 46, Credit Card 56, Investment 3; 14 distinct categories; all HKD; dates span 2022/07/16 18:28 to 2026/10/30 10:39 (assert the first data row against the fixture rather than hard-coding it here);
  - synthetic inputs: BOM stripped (once); CRLF; quoted memo with a comma, `""` and a newline, and the next row's line number is still correct; an all-empty line in the middle is skipped and later line numbers still count it; reordered and extra columns; missing `note` gives a null memo; missing `Amount` is a file error; `2026/02/30` and `2026/1/5 25:00` are `invalidDate`; `2026/1/5 9:05` is accepted; seconds accepted; short row gives `columnCount`; invalid UTF-8 gives `notUtf8`; **a fixture with an unterminated quote in a memo gives `parse`**; 10,001 rows gives `tooManyRows`; header only gives `empty`.
- `csv_import_matcher_test.dart` (the matcher is a feature helper; this follows the `amount_formula_test.dart` precedent), with real `AppLocalizations` via `lookupAppLocalizations`:
  - every row of the category sample table: the 10 label matches, the 3 creates, and 收入;
  - income marker: note 薪資, 薪资 and "Salary" go to `category.income.salary`; any other note, an empty note and a null note go to `category.income.other`;
  - a retired, archived `category.personal` row is still matched by its label (個人) when present;
  - English "Investment" goes to the expense key;
  - an existing custom "食物" is matched by `customName`;
  - archived category matches are used;
  - accounts: tiers 1, 1b, 2, 2b, 2c and 3, with the sample's Cash, Investment and Credit Card outcomes; 2b's initial resolution is non-null and marked new, 1b/2c/3 are null;
  - an archived account named "Credit Card" is not auto-matched but appears in the options as archived;
  - normalization: `' cash '` matches "Cash";
  - locale independence: the result is the same whatever the app locale.

**Unit — repositories** (`test/unit/repositories/transaction_repository_test.dart`, in-memory Drift, `DriftTransactionRepository(db, clock: …)` built directly)
- `insertImported` keeps `createdAt`, sets every row's `updatedAt` to one clock value (a clock that advances per call still yields a single value), keeps `date` from the model, sets `amountFormula` to null, and inserts in the given order (ascending ids). It throws `CurrencyNotFoundException` for an unknown code, and it is atomic inside an outer `db.transaction` that throws, so nothing persists.
- With `PRAGMA foreign_keys = ON`, a batch in which one row has `categoryId: 999999` throws and leaves 0 rows.
- `getImportSignatures` includes both bounds, filters on `created_at` (not `date`), and returns only the four fields.
- Update every fake or mock that `implements TransactionRepository` in `test/`.

**Unit — use case** (`test/unit/use_cases/csv_import_use_case_test.dart`, in-memory Drift with `runTestSeed`, fake `CsvFileService`)
- Loading the sample gives 105 `CsvImportRow`s in HKD minor units and 0 duplicates.
- An unknown currency becomes row errors, and its Account/Category values are not in the rows to import.
- A `CsvFileTooLargeException` from the service surfaces as `CsvFileException(tooLarge)`.
- The full sample commit, with Credit Card → `createTypeAndAccount`, gives 105 transactions, 1 new type, 2 new accounts and 3 new categories. 收入 rows sum as income through `watchDailyTotalsByType`; exactly 1 lands in Salary and 9 in Other income. Every row's `date` is midnight local and its `createdAt` is the Recorded At.
- With 還款 set to income, its 3 rows sum as income.
- Inserted ids follow `(createdAt ASC, line DESC)`: the newest row has the highest id, and the most recent memo per category ranks first in `watchRecentMemosForCategory`.
- Loading the sample again after a commit gives 0 rows to import and 105 duplicates, **even when** the first commit sent Credit Card to an existing account and that account has since been archived.
- Dedup is multiset-based: a file with 2 identical rows against 1 existing row inserts 1.
- When the commit-time recount finds every row of a to-be-created category already present (rows inserted between load and commit), that category is not created.
- **Atomicity:** real account-type, account and category repositories on the same in-memory `AppDatabase`, plus a `TransactionRepository` whose `insertImported` throws. After the failed commit, the counts of account types, accounts, categories and transactions are unchanged.
- A cancelled pick returns null.

**Unit — controller** (`test/unit/controllers/csv_import_controller_test.dart`, mocktail, `@Dependencies([CsvImportController])` on `main`). `build()` is synchronous, so tests subscribe with `container.listen` and read `container.read(csvImportControllerProvider)` directly; there is no `.future`.
- `idle → loading → preview`.
- `canCommit` is false until Credit Card is resolved, and the pre-selected Investment resolution counts as decided.
- `canCommit` is false when there are 0 rows to import.
- `setAccountResolution` and `setNewCategoryType` update the preview; `duplicateCount` and the confirm count are unchanged.
- `commit` goes to `committing → done`.
- `refreshAll` is called exactly once, with `defaultCurrency` falling back to `initialDefaultCurrency`, when a non-default currency was imported, and not at all when every currency is the default.
- A commit exception goes to `failure(commitFailed)`.
- A cancelled pick returns to `idle`.
- Each `CsvFileException(kind)` maps to `failure(kind)`.
- No state write after dispose.

**Widget** (`test/widget/features/settings/`)
- `settings_screen_test.dart`: the tile exists, and tapping it pushes `/settings/import` (`_StubRouter` stub).
- `csv_import_screen_test.dart`, with a fake controller overriding `build()`:
  - each state renders;
  - the balance note is shown in the preview;
  - the Import button is disabled while a decision is pending, and shows "Nothing new to import" when the count is 0;
  - the tier 2b entry shows the New badge and is not marked as needing a decision;
  - the decision sheet shows options 1 and 3 for tier 3, and 1, 2 and 3 for tier 2b with option 2 selected; an archived same-name account is listed with "(archived)";
  - the type toggle on a to-be-created category calls `setNewCategoryType`;
  - invalid rows show line number + reason and no field values;
  - pop is blocked while committing;
  - **2× text scale** with no overflow;
  - the 600dp dialog layout.

**Integration** (`test/integration/csv_import_flow_test.dart`): bootstrapped app with a fake `CsvFileService` override returning the sample bytes. Go Settings → tile → choose → resolve Credit Card (create) → Import → done. Then assert through the repository, not Home (Home reads `DateTime.now()` and has no clock provider, so a Home assertion would only pass on 2026-10-30): `watchByDay(DateTime(2026, 10, 30)).first` returns that day's imported rows, and the transaction count is 105. Drift writes before the first `pump` run in `tester.runAsync`.

**l10n:** `arb_audit_test.dart` passes after its `_expectedEnKeys` update. Add a small test that the `csvImport*` keys exist in en, zh_TW and zh_CN.

**Architecture:** `flutter test test/unit/architecture/` passes with no new baseline entries.

Update the per-slice coverage map in `docs/architecture/testing.md`, including the matcher test's location under `test/unit/utils/`.

---

## Commit / Slice Plan

Each commit must pass `dart analyze --fatal-infos` and `flutter test` on its own. Regenerate generated parts (`build_runner`, `gen-l10n`) in the commit that changes their sources.

| #  | Commit                                                                                                                                                                                              | Contents                                                                                                                                                                                                                                                                                                                                  |
|----|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 0  | *(landed)* `feat(categories): add built-in Investment expense category`, `feat(l10n): rename zh category labels to Fortune City's names`, `feat(categories): retire the built-in Personal category` | Not part of this spec.                                                                                                                                                                                                                                                                                                                    |
| 1  | `docs: add CSV import design spec`                                                                                                                                                                  | This file plus the sample fixture `test/data/import_fortune_city_data.csv`.                                                                                                                                                                                                                                                               |
| 2  | `build(deps): add file_selector and csv for CSV import`                                                                                                                                             | `pubspec.yaml` + `pubspec.lock`. Move `csv` from Phase 3 to Phase 2 in the PRD dependency table. Record the APK size delta in the body.                                                                                                                                                                                                   |
| 3  | `feat(core): add half-up decimal-string to minor-units rounding`                                                                                                                                    | `decimal_rounding.dart` + tests.                                                                                                                                                                                                                                                                                                          |
| 4  | `feat(core): parse Fortune City CSV exports`                                                                                                                                                        | Parser + `data/models/csv_import.dart` (parse-side types, `CsvFileException`) + tests against the sample fixture and the unterminated-quote fixture.                                                                                                                                                                                      |
| 5  | `feat(data): add import insert path that keeps createdAt`                                                                                                                                           | `insertImported`, `getImportSignatures` + DAO query (regenerated `.g.dart`), and the fakes in `test/`. Document the timestamp exception in `PRD.md`, `docs/architecture/data-model.md` and the repository header.                                                                                                                         |
| 6  | `feat(data): add CSV import use case with atomic commit and dedup`                                                                                                                                  | `csv_file_service.dart`, `csv_import_use_case.dart`, the plan and result models, providers + regenerated `.g.dart`, and tests.                                                                                                                                                                                                            |
| 7  | `refactor(accounts): extract accountTypeDisplayNameForKey`                                                                                                                                          | Behaviour unchanged; the existing tests stay green.                                                                                                                                                                                                                                                                                       |
| 8  | `feat(settings): match CSV accounts and categories against l10n labels`                                                                                                                             | `csv_import_matcher.dart` + `test/unit/utils/csv_import_matcher_test.dart`.                                                                                                                                                                                                                                                               |
| 9  | `feat(settings,l10n): add CSV import controller and strings`                                                                                                                                        | Controller, state, the ARB keys in 3 files + regenerated `lib/l10n/`, the `_expectedEnKeys` update in `arb_audit_test.dart`, and controller tests.                                                                                                                                                                                        |
| 10 | `feat(settings,app): add Import from CSV screen and Settings entry`                                                                                                                                 | Screen, widgets, route + regenerated `router.g.dart`, the Settings tile, and widget + integration tests. Add `/settings/import` to the `PRD.md` route table.                                                                                                                                                                              |
| 11 | `docs: mark Fortune City CSV import as shipped`                                                                                                                                                     | `PRD.md` status/roadmap and folder tree (`features/settings/csv_import/`, `data/services/csv_file_service.dart`, `data/use_cases/csv_import_use_case.dart`, `core/utils/decimal_rounding.dart`, `core/utils/fortune_city_csv_parser.dart`), `AGENTS.md` project status, `README.md`, and the `docs/architecture/testing.md` coverage map. |

PR title (per AGENTS.md): `Problem(settings): data from Fortune City cannot be migrated into Ledgerly`.

---

## Decisions

Answered by the user on 2026-10-30.

| #   | Question                                                | Decision                                                                                                                                                                                                                                                |
|-----|---------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| D-1 | "Round up to 2 decimal points"                          | **Normal rounding** (half-up) on the decimal string to `min(2, currency.decimals)` places: `23.6000003814697 → 23.60`. Not a ceiling.                                                                                                                   |
| D-2 | Rows whose Category is 收入                             | **Income.** Note 薪資 (the Salary label in any locale) → `category.income.salary`; any other note → `category.income.other`.                                                                                                                            |
| D-3 | Type of newly created categories (還款, 個人護理, 休閒) | Not answered; the recommended default stands: an Expense/Income toggle per new category, default Expense. A wrong type cannot be fixed after import because `CategoryTypeLockedException` locks it once used.                                           |
| D-4 | Near-miss labels (食物 vs 飲食, …)                      | **Rename the built-in labels** instead of aliasing: zh_TW Food 食物, Drinks 飲品, Shopping 消費, Housing 居家, Medical 醫藥 (zh_CN: 食物, 饮品, 消费, 居家, 医药), and **retire Personal**. Matching stays exact.                                       |
| D-5 | Duplicate detection on re-import                        | **Yes.** Multiset dedup on `(createdAt, amount, currency, memo)`, independent of account and category resolutions. Known limits: a timezone change between imports, or editing an imported row's amount or memo. A v8 `import_key` column is not added. |

### Design notes (not product choices)

- **Recorded At → `createdAt`, and `date`.** `created_at` = Recorded At, as requested. `date` = the start of that day, because Home, search, charts and balances filter on `date`, and every other write path stores midnight there. Setting only `created_at` would put every imported row on today.
- **Account vs account type.** CSV Account values resolve to **accounts**: first by account name, then by account-type label in any locale. A value that matches no type is a "new account type", and the user is asked to use an existing account or create a type plus account. Creating only a type is not offered, because transactions need an `account_id`.
- **Invalid rows.** Skip them and list them (line number + reason) in the preview; the user confirms the valid remainder.
- **Limits and encoding.** 5 MB, 10,000 rows, UTF-8 only (with or without a BOM). The sample is about 5.8 KB and 105 rows.
- **Dependencies.** `file_selector` (first-party, SPM, no Android permissions) + `csv` 8.x (pure Dart, already named in the PRD; moved from Phase 3 to Phase 2).
