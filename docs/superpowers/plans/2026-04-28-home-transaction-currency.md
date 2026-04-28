# Home Calendar Navigation And Transaction Currency Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the approved Home calendar-day browsing, transaction-level currency, grouped account balances, and matching `PRD.md` updates without changing the Drift schema.

**Architecture:** Keep repository ownership and reactive flow exactly as `PRD.md` and `AGENTS.md` require: repositories stay the SSOT, controllers project immutable state, widgets own only layout/animation/routing concerns. Reuse the existing `lib/features/accounts/widgets/currency_display.dart` helper instead of creating a second currency-name mapper, keep Home's queued day-transition state in the widget layer, and treat `transactions.currency` as the existing MVP source of truth.

**Tech Stack:** Flutter, Riverpod, Freezed, Drift, `flutter gen-l10n`, `build_runner`, widget/unit/integration tests.

---

## Locked Decisions

- Keep this as one plan. The spec touches Home, Transactions, Accounts, and `PRD.md`, but the work is one coupled product rule: transaction currency is independent, Home/Accounts stay grouped by original currency, and no schema migration is required.
- Do not create a second seeded-currency-name helper. Extend `lib/features/accounts/widgets/currency_display.dart` and import it from the Settings and Transactions widgets that need the same display logic.
- Keep Home's swipe/button/date-picker animation queue in the widget layer (`lib/features/home/home_screen.dart`). Do not move animation state into `HomeController`.
- Replace activity-day stepping with true calendar-day stepping in `HomeController`, but keep first-run detection driven by `watchDaysWithActivity()` because it is still the cheapest no-history signal.
- Add `AccountRepository.watchBalanceByCurrency(int accountId)` and migrate the Accounts slice to it. Remove `watchBalanceMinorUnits(...)` once no production callers remain.
- Do not bump `schemaVersion`, do not add a new `drift_schemas/` snapshot, and do not touch migrations. `transactions.currency` already exists and stays the SSOT.
- Run `flutter gen-l10n` immediately after ARB edits. Run `dart run build_runner build --delete-conflicting-outputs` after any `@freezed` / `@riverpod` signature change.
- Execute in a dedicated git worktree. If you are already in one for this feature, skip the worktree-creation steps.

## References To Keep Open

- Spec: `docs/superpowers/specs/2026-04-28-home-transaction-currency-design.md`
- Product source of truth: `PRD.md`
- Repo rules: `CLAUDE.md`, `AGENTS.md`
- Related learnings:
  - `docs/solutions/logic-errors/home-delete-undo-stream-coordination-2026-04-26.md`
  - `docs/solutions/best-practices/reactive-feature-flow-ownership-2026-04-25.md`
  - `docs/solutions/logic-errors/account-transaction-currency-invariant-2026-04-25.md`
  - `docs/solutions/logic-errors/transaction-form-workflow-integrity-2026-04-25.md`
  - `docs/solutions/database-issues/drift-schema-v1-snapshot-drift-2026-04-23.md`

## File Map

- Modify: `PRD.md`
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh_TW.arb`
- Modify: `l10n/app_zh_CN.arb`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_en.dart`
- Modify: `lib/l10n/app_localizations_zh.dart`
- Modify: `test/unit/l10n/arb_audit_test.dart`
- Modify: `lib/features/accounts/widgets/currency_display.dart`
- Modify: `lib/features/settings/widgets/default_currency_picker_sheet.dart`
- Modify: `lib/features/home/home_controller.dart`
- Modify: `lib/features/home/home_state.dart`
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/home/widgets/day_navigation_header.dart`
- Modify: `lib/features/home/widgets/summary_strip.dart`
- Modify: `lib/features/transactions/transaction_form_state.dart`
- Modify: `lib/features/transactions/transaction_form_controller.dart`
- Modify: `lib/features/transactions/transaction_form_screen.dart`
- Modify: `lib/features/transactions/transactions_providers.dart`
- Modify: `lib/features/transactions/widgets/account_selector_tile.dart`
- Modify: `lib/features/transactions/widgets/amount_display.dart`
- Create: `lib/features/transactions/widgets/currency_selector_tile.dart`
- Create: `lib/features/transactions/widgets/currency_picker_sheet.dart`
- Modify: `lib/data/repositories/transaction_repository.dart`
- Modify: `lib/data/repositories/repository_exceptions.dart`
- Modify: `lib/data/repositories/account_repository.dart`
- Modify: `lib/features/accounts/accounts_controller.dart`
- Modify: `lib/features/accounts/accounts_state.dart`
- Modify: `lib/features/accounts/accounts_providers.dart`
- Modify: `lib/features/accounts/accounts_screen.dart`
- Modify: `lib/features/accounts/widgets/account_tile.dart`
- Create: `test/unit/utils/currency_display_name_test.dart`
- Modify: `test/unit/controllers/home_controller_test.dart`
- Modify: `test/widget/features/home/home_screen_test.dart`
- Modify: `test/widget/features/home/day_navigation_header_test.dart`
- Modify: `test/widget/features/home/summary_strip_test.dart`
- Modify: `test/unit/controllers/transaction_form_controller_test.dart`
- Modify: `test/widget/features/transactions/transaction_form_screen_test.dart`
- Modify: `test/unit/repositories/transaction_repository_test.dart`
- Modify: `test/unit/repositories/repository_exceptions_test.dart`
- Modify: `test/unit/repositories/account_repository_test.dart`
- Modify: `test/unit/controllers/accounts_controller_test.dart`
- Modify: `test/widget/features/accounts/accounts_screen_test.dart`
- Modify: `test/integration/transaction_mutation_flow_test.dart`
- Modify: `test/integration/multi_currency_flow_test.dart`

## Chunk 1: Preflight, L10n, And Shared Currency Naming

### Task 1: Start in a dedicated worktree and record the clean baseline

**Files:**
- Modify: none

**Why this task exists:** The spec spans multiple subsystems. Isolation matters because you will be touching generated l10n files, Freezed/Riverpod output, and several feature slices.

- [ ] **Step 1: Create a dedicated worktree if you are not already in one**

Run:

```bash
git worktree add ../ledgerly-home-transaction-currency -b feature/home-transaction-currency
```

Expected:
- a sibling worktree appears at `../ledgerly-home-transaction-currency`
- the new branch is `feature/home-transaction-currency`

- [ ] **Step 2: Move into the worktree and confirm the branch**

Run:

```bash
git status --short --branch
```

Expected:
- output starts with `## feature/home-transaction-currency`
- no unrelated staged changes inside the new worktree

- [ ] **Step 3: Capture the verification baseline before edits**

Run:

```bash
flutter test test/unit/l10n/arb_audit_test.dart
```

Expected:
- PASS

- [ ] **Step 4: Capture the current import-boundary/analyzer baseline**

Run:

```bash
dart format . && dart run import_lint && flutter analyze
```

Expected:
- `dart format .` exits 0
- `dart run import_lint` exits 0
- `flutter analyze` ends with `No issues found!`

- [ ] **Step 5: Commit the baseline-only checkpoint if you had to create the worktree**

```bash
git commit --allow-empty -m "chore: start home currency worktree"
```

### Task 2: Add the missing ARB keys and regenerate localized output

**Files:**
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh_TW.arb`
- Modify: `l10n/app_zh_CN.arb`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_en.dart`
- Modify: `lib/l10n/app_localizations_zh.dart`
- Modify: `test/unit/l10n/arb_audit_test.dart`

**Why this task exists:** The spec adds new UI copy for Home, Transactions, Accounts, and seeded fiat names. The helper work in Task 3 cannot land until the generated getters exist.

- [ ] **Step 1: Add the new English keys to `l10n/app_en.arb`**

Append entries for:

```json
"homeEmptyDayMessage": "No transaction",
"homeJumpToToday": "Jump to today",
"txCurrencyLabel": "Currency",
"txCurrencyPickerTitle": "Pick currency",
"txCurrencySearchHint": "Search currencies",
"txCurrencyChangeConfirmAction": "Change and Clear",
"txAmountPlaceholderInCurrency": "Enter amount in {code}",
"accountsBalanceMore": "+{count} more",
"currencyUsd": "US Dollar",
"currencyEur": "Euro",
"currencyJpy": "Japanese Yen",
"currencyTwd": "New Taiwan Dollar",
"currencyCny": "Chinese Yuan",
"currencyHkd": "Hong Kong Dollar",
"currencyGbp": "British Pound",
"currencyCad": "Canadian Dollar",
"currencySgd": "Singapore Dollar",
"currencyAud": "Australian Dollar",
"currencyNzd": "New Zealand Dollar"
```

Also update the existing values for:

```json
"txCurrencyChangeConfirmTitle": "Change currency?",
"txCurrencyChangeConfirmBody": "The amount entered will be cleared."
```

- [ ] **Step 2: Add matching Traditional Chinese keys to `l10n/app_zh_TW.arb`**

Use real translations, not English fallbacks. Include the same keys as Step 1. Keep placeholders identical:

```json
"txAmountPlaceholderInCurrency": "輸入 {code} 金額",
"accountsBalanceMore": "+{count} 個更多"
```

- [ ] **Step 3: Add matching Simplified Chinese keys to `l10n/app_zh_CN.arb`**

Use the same key set and placeholder names as Steps 1-2.

- [ ] **Step 4: Add the new keys to `test/unit/l10n/arb_audit_test.dart`**

Extend `_expectedEnKeys` with every new key from Steps 1-3 so the ARB inventory stays authoritative.

- [ ] **Step 5: Regenerate checked-in l10n output**

Run:

```bash
flutter gen-l10n
```

Expected:
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_zh.dart`

all update without errors.

- [ ] **Step 6: Verify the ARB inventory before touching product code**

Run:

```bash
flutter test test/unit/l10n/arb_audit_test.dart
```

Expected:
- PASS

### Task 3: Make seeded currency names resolve from one shared helper

**Files:**
- Modify: `lib/features/accounts/widgets/currency_display.dart`
- Modify: `lib/features/settings/widgets/default_currency_picker_sheet.dart`
- Create: `test/unit/utils/currency_display_name_test.dart`

**Why this task exists:** The spec depends on searchable currency pickers showing code + full name. The repo already has a currency-name helper; extend it instead of duplicating logic.

- [ ] **Step 1: Replace the stub switch in `lib/features/accounts/widgets/currency_display.dart` with real seeded-key mappings**

Use the same pattern already used in `lib/features/categories/widgets/category_display.dart` and `lib/features/accounts/widgets/account_type_display.dart`:

```dart
return switch (currency.nameL10nKey) {
  'currency.usd' => l10n.currencyUsd,
  'currency.eur' => l10n.currencyEur,
  'currency.jpy' => l10n.currencyJpy,
  'currency.twd' => l10n.currencyTwd,
  'currency.cny' => l10n.currencyCny,
  'currency.hkd' => l10n.currencyHkd,
  'currency.gbp' => l10n.currencyGbp,
  'currency.cad' => l10n.currencyCad,
  'currency.sgd' => l10n.currencySgd,
  'currency.aud' => l10n.currencyAud,
  'currency.nzd' => l10n.currencyNzd,
  _ => currency.code,
};
```

- [ ] **Step 2: Delete the private fallback-only display-name helper from `lib/features/settings/widgets/default_currency_picker_sheet.dart`**

Import the shared helper instead:

```dart
import '../../accounts/widgets/currency_display.dart';
```

Then replace `_displayName(c)` with `currencyDisplayName(c, l10n)`.

- [ ] **Step 3: Add a focused pure-function regression test**

Create `test/unit/utils/currency_display_name_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/features/accounts/widgets/currency_display.dart';
import 'package:ledgerly/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('seeded currencies resolve localized full names', () {
    expect(
      currencyDisplayName(
        const Currency(code: 'USD', decimals: 2, nameL10nKey: 'currency.usd'),
        l10n,
      ),
      'US Dollar',
    );
  });

  test('customName wins over seeded l10n', () {
    expect(
      currencyDisplayName(
        const Currency(
          code: 'USD',
          decimals: 2,
          nameL10nKey: 'currency.usd',
          customName: 'Travel Card Dollars',
        ),
        l10n,
      ),
      'Travel Card Dollars',
    );
  });

  test('unknown keys still fall back to code', () {
    expect(
      currencyDisplayName(
        const Currency(code: 'XYZ', decimals: 2, nameL10nKey: 'currency.xyz'),
        l10n,
      ),
      'XYZ',
    );
  });
}
```

- [ ] **Step 4: Verify the helper and import-boundary changes**

Run:

```bash
dart format . && flutter test test/unit/utils/currency_display_name_test.dart && dart run import_lint
```

Expected:
- formatting succeeds
- helper test PASS
- `import_lint` still exits 0 even though Settings now imports the shared Accounts helper

- [ ] **Step 5: Commit the groundwork chunk**

```bash
git add l10n/app_en.arb l10n/app_zh_TW.arb l10n/app_zh_CN.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_zh.dart test/unit/l10n/arb_audit_test.dart lib/features/accounts/widgets/currency_display.dart lib/features/settings/widgets/default_currency_picker_sheet.dart test/unit/utils/currency_display_name_test.dart
git commit -m "feat(l10n): localize seeded currency names"
```

## Chunk 2: Home Calendar-Day Browsing And Gap-Day UI

### Task 4: Rewrite Home controller expectations around real calendar days

**Files:**
- Modify: `test/unit/controllers/home_controller_test.dart`
- Modify: `lib/features/home/home_state.dart`
- Modify: `lib/features/home/home_controller.dart`

**Why this task exists:** The controller is still built around days-with-activity for prev/next and summary streams anchored to today. The spec requires selected-day summaries and one-day stepping across gap days.

- [ ] **Step 1: Rewrite the controller tests before touching implementation**

Update `test/unit/controllers/home_controller_test.dart` so it proves all of these:

```dart
test('calendar prev/next step one day at a time across gap days', () async {
  // today -> yesterday -> twoDaysAgo, regardless of activity list gaps
});

test('selected-day summary streams follow pinDay instead of staying on today', () async {
  // verify watchDailyTotalsByType(selectedDay) and watchMonthNetByCurrency(selectedDay)
});

test('next day is capped at today', () async {
  // selecting next from today is a no-op
});

test('first-run empty still depends on no history at all', () async {
  // empty history -> HomeEmpty; non-empty history + no rows on selectedDay -> HomeData with []
});
```

Do not keep assertions that `prevDayWithActivity` / `nextDayWithActivity` skip empty days. Those are the old behavior.

- [ ] **Step 2: Run the controller file to watch it fail for the right reason**

Run:

```bash
flutter test test/unit/controllers/home_controller_test.dart
```

Expected:
- FAIL on the new calendar-day expectations
- old activity-day logic still visible in the failure output

- [ ] **Step 3: Simplify `HomeState.data` to calendar-day navigation flags**

Replace the activity-day chevron fields in `lib/features/home/home_state.dart` with hard-bound booleans:

```dart
required bool canGoPrev,
required bool canGoNext,
```

Keep `activityDays` itself because the tablet activity pane can still list days with transactions as a shortcut surface.

- [ ] **Step 4: Change `HomeController` to step by calendar day, not activity day**

In `lib/features/home/home_controller.dart`:

```dart
static final DateTime _minSelectableDay = DateTime(1900);

Future<void> selectPrevDay() async {
  _syncTodayAnchor();
  if (_selectedDay.isAtSameMomentAs(_minSelectableDay)) return;
  _selectedDay = _selectedDay.subtract(const Duration(days: 1));
  _composer?.changeSelectedDay(_selectedDay);
}

Future<void> selectNextDay() async {
  _syncTodayAnchor();
  if (DateHelpers.isSameDay(_selectedDay, _todayAnchor)) return;
  _selectedDay = _selectedDay.add(const Duration(days: 1));
  if (_selectedDay.isAfter(_todayAnchor)) _selectedDay = _todayAnchor;
  _composer?.changeSelectedDay(_selectedDay);
}
```

Also re-subscribe the summary streams with `selectedDay`, not `todayAnchor`, so `watchDailyTotalsByType(...)` and `watchMonthNetByCurrency(...)` reflect the visible day/month.

- [ ] **Step 5: Keep first-run detection but stop using activity-day neighbors for chevrons**

Inside `_Composer._emitIfReady()`:

```dart
final today = _todayGetter();
final canGoPrev = selectedDay.isAfter(DateTime(1900));
final canGoNext = selectedDay.isBefore(today);
```

Use `activity.isEmpty` only for the first-run empty-state branch.

Also expose one controller-owned normalized today value in `HomeState.data` so the widget layer does not recompute `DateTime.now()` independently. Add:

```dart
required DateTime today,
```

Populate it from `_todayGetter()`. The rest of this plan uses `data.today` for `canGoNext`, jump-to-today visibility, and Home date-picker bounds.

- [ ] **Step 6: Regenerate Freezed/Riverpod output after the state-shape changes**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected:
- `lib/features/home/home_state.freezed.dart`
- `lib/features/home/home_controller.g.dart`

update successfully.

- [ ] **Step 7: Re-run the controller tests and stop only when the new rules pass**

Run:

```bash
flutter test test/unit/controllers/home_controller_test.dart
```

Expected:
- PASS

### Task 5: Update the Home widgets for jump-to-today, bounded date picking, and the empty-day card

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/home/widgets/day_navigation_header.dart`
- Modify: `lib/features/home/widgets/summary_strip.dart`
- Modify: `test/widget/features/home/home_screen_test.dart`
- Modify: `test/widget/features/home/day_navigation_header_test.dart`
- Modify: `test/widget/features/home/summary_strip_test.dart`

**Why this task exists:** The widget tree still disables next on activity-day boundaries, opens an unbounded date picker, and renders a text-only gap-day empty state.

- [ ] **Step 1: Add failing widget coverage for the approved Home UI**

Extend the Home widget tests with cases for:

```dart
testWidgets('gap day renders transaction-style empty card with No transaction', ...);
testWidgets('Jump to today button shows only when selectedDay != today', ...);
testWidgets('day picker lastDate is today', ...);
testWidgets('next chevron stays enabled on empty intermediate days until today', ...);
```

Update `test/widget/features/home/day_navigation_header_test.dart` so it asserts `canGoPrev` / `canGoNext` booleans instead of activity-day semantics.

Update `test/widget/features/home/summary_strip_test.dart` so it checks the jump-to-today affordance and selected-day-driven control state instead of assuming the strip is today-only.

- [ ] **Step 2: Run the Home widget suite and confirm the failures are all spec-aligned**

Run:

```bash
flutter test test/widget/features/home/home_screen_test.dart test/widget/features/home/day_navigation_header_test.dart test/widget/features/home/summary_strip_test.dart
```

Expected:
- FAIL on missing jump button / wrong empty-state copy / wrong date-picker bounds

- [ ] **Step 3: Wire `canGoPrev` / `canGoNext` through every Home layout path**

In `lib/features/home/home_screen.dart` and `lib/features/home/widgets/day_navigation_header.dart`, replace:

```dart
canGoPrev: data.prevDayWithActivity != null,
canGoNext: data.nextDayWithActivity != null,
```

with:

```dart
canGoPrev: data.canGoPrev,
canGoNext: data.canGoNext,
```

Do not keep the old activity-day-only comments.

Also update the wide-layout `_TwoPane` path so it no longer calls:

```dart
onPrev: () => onSelectActivityDay(data.prevDayWithActivity!),
onNext: () => onSelectActivityDay(data.nextDayWithActivity!),
```

Instead, thread the same calendar-day `onPrev` / `onNext` callbacks used by `_SinglePane` into `_TwoPane`.

- [ ] **Step 4: Cap the Home date picker at today**

Change the `showDatePicker(...)` call in `lib/features/home/home_screen.dart` so `lastDate` is today at local midnight:

```dart
final lastDate = data.today;
```

Use that in `_onPickDay(...)`. Do not leave `DateTime(9999, 12, 31)` anywhere in Home.

- [ ] **Step 5: Move the Jump to today control into `SummaryStrip`**

Add `selectedDay`, `showJumpToToday`, and `onJumpToToday` parameters to `SummaryStrip` and render a small trailing text button above the currency groups:

```dart
if (showJumpToToday)
  Align(
    alignment: Alignment.centerRight,
    child: TextButton(
      onPressed: onJumpToToday,
      child: Text(l10n.homeJumpToToday),
    ),
  ),
```

Pass the real values from `HomeScreen` using the controller-owned normalized date from Task 4:

```dart
showJumpToToday: !DateHelpers.isSameDay(data.selectedDay, data.today)
```

so the button and `canGoNext` use the same normalized source of truth.

- [ ] **Step 6: Replace the text-only gap-day state with a transaction-style card**

Inside `lib/features/home/home_screen.dart`, replace the `SliverFillRemaining`/`Center(Text(...))` branch with a `SliverToBoxAdapter` that uses the same container shell as `_TransactionListCard` and a constrained row-height body:

```dart
SliverPadding(
  padding: const EdgeInsets.symmetric(
    horizontal: homePageCardHorizontalPadding - transactionPadding,
    vertical: 12,
  ),
  sliver: SliverToBoxAdapter(
    child: _EmptyDayCard(message: l10n.homeEmptyDayMessage),
  ),
)
```

Keep the first-run `HomeEmpty` CTA path untouched.

- [ ] **Step 7: Re-run the Home widget suite at normal and 2x text scale**

Run:

```bash
flutter test test/widget/features/home/home_screen_test.dart test/widget/features/home/day_navigation_header_test.dart test/widget/features/home/summary_strip_test.dart
```

Expected:
- PASS
- existing 2x text-scale checks still pass

- [ ] **Step 8: Commit the calendar-day UI change**

```bash
git add lib/features/home/home_controller.dart lib/features/home/home_state.dart lib/features/home/home_screen.dart lib/features/home/widgets/day_navigation_header.dart lib/features/home/widgets/summary_strip.dart test/unit/controllers/home_controller_test.dart test/widget/features/home/home_screen_test.dart test/widget/features/home/day_navigation_header_test.dart test/widget/features/home/summary_strip_test.dart
git commit -m "feat(home): browse real calendar days"
```

## Chunk 3: Home Day-Transition Animation Queue

### Task 6: Add queued one-step Home animations in the widget layer

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `test/widget/features/home/home_screen_test.dart`

**Why this task exists:** The spec requires repeated swipe/button/date-picker actions to feel like one day-switch interaction, including queued steps during a running animation.

- [ ] **Step 1: Add failing widget coverage for the animation queue contract**

Add tests in `test/widget/features/home/home_screen_test.dart` for:

```dart
testWidgets('rapid swipes queue one-day transitions instead of dropping steps', ...);
testWidgets('date-picker jump uses forward animation when picked day is later', ...);
testWidgets('save returning to the same selectedDay does not trigger a switch animation', ...);
```

Keep these tests focused on stateful widget behavior. Do not push queue logic into `HomeController` tests.

- [ ] **Step 2: Run just the new Home animation tests**

Run:

```bash
flutter test test/widget/features/home/home_screen_test.dart
```

Expected:
- FAIL on the new animation assertions only

- [ ] **Step 3: Convert `_HomeScreenState` to own an explicit slide animation controller**

Use the Flutter animation pattern directly in `lib/features/home/home_screen.dart`:

```dart
class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _daySwitchController;
  late Animation<Offset> _incomingOffset;
  int _queuedDaySteps = 0;
  int _activeDirection = 0; // -1 older, +1 newer
}
```

Dispose the controller in `dispose()`.

- [ ] **Step 4: Route prev/next/swipe/date-picker requests through a tiny queue API**

Add private widget-layer helpers in `lib/features/home/home_screen.dart`:

```dart
void _enqueueDayStep(int delta) { ... }
Future<void> _runNextQueuedStep() async { ... }
Future<void> _jumpToDay(DateTime pickedDay) async { ... }
```

Rules:
- `delta` is always one day
- repeated inputs during an active animation increment/decrement the queue
- each cycle advances exactly one day and then drains the next queued step
- if the requested day equals the current visible day, update in place and do not animate

- [ ] **Step 5: Animate only the day-content region, not the whole scaffold**

Wrap the portion under the summary strip/header in a keyed transition container keyed by `data.selectedDay`. Use a slide transition whose sign matches the requested direction:

```dart
SlideTransition(
  position: _incomingOffset,
  child: KeyedSubtree(
    key: ValueKey<DateTime>(data.selectedDay),
    child: _buildDayBody(...),
  ),
)
```

Do not rebuild the FAB or top-level scaffold during the animation.

- [ ] **Step 6: Re-run the Home widget suite until the queue behavior is stable**

Run:

```bash
flutter test test/widget/features/home/home_screen_test.dart
```

Expected:
- PASS, including the new repeated-swipe and same-day-no-animation cases

- [ ] **Step 7: Commit the animation chunk**

```bash
git add lib/features/home/home_screen.dart test/widget/features/home/home_screen_test.dart
git commit -m "feat(home): animate queued day navigation"
```

## Chunk 4: Transaction-Level Currency

### Task 7: Replace the old account-currency invariant with transaction-level currency tests

**Files:**
- Modify: `test/unit/controllers/transaction_form_controller_test.dart`
- Modify: `test/widget/features/transactions/transaction_form_screen_test.dart`
- Modify: `test/unit/repositories/transaction_repository_test.dart`
- Modify: `test/unit/repositories/repository_exceptions_test.dart`

**Why this task exists:** The current tests still codify the invariant that transaction currency must match account currency. That is the exact behavior the spec removes.

- [ ] **Step 1: Rewrite the repository test that currently expects a mismatch exception**

In `test/unit/repositories/transaction_repository_test.dart`, replace the old mismatch case with a passing cross-currency save:

```dart
test('cross-currency transaction on an account saves without throwing', () async {
  final saved = await txRepo.save(
    sampleTx(
      currency: const Currency(
        code: 'JPY',
        decimals: 0,
        symbol: '¥',
        nameL10nKey: 'currency.jpy',
      ),
    ),
  );

  expect(saved.currency.code, 'JPY');
  expect(saved.accountId, fixtures.accountId);
});
```

- [ ] **Step 2: Delete the exception-surface test for `TransactionAccountCurrencyMismatchException`**

Remove the `TransactionAccountCurrencyMismatchException` group from `test/unit/repositories/repository_exceptions_test.dart`.

- [ ] **Step 3: Add controller tests for the new `currencyTouched` rule**

In `test/unit/controllers/transaction_form_controller_test.dart`, add cases for:

```dart
test('account change re-seeds currency before currencyTouched becomes true', ...);
test('account change leaves displayCurrency unchanged after user picks currency', ...);
test('selectCurrency with non-zero amount refuses until clear flag is supplied', ...);
test('save persists displayCurrency rather than selectedAccount.currency', ...);
```

- [ ] **Step 4: Add widget tests for the currency row, searchable picker, and clear-confirm dialog**

Extend `test/widget/features/transactions/transaction_form_screen_test.dart` with cases for:

```dart
testWidgets('currency row opens searchable picker and shows code + full name', ...);
testWidgets('changing currency with amount shows Change and Clear dialog', ...);
testWidgets('cancel keeps the old currency and amount', ...);
testWidgets('Change and Clear empties amount and shows Enter amount in [code]', ...);
```

- [ ] **Step 5: Run the affected transaction/repository tests and confirm the old invariant is now the only thing failing**

Run:

```bash
flutter test test/unit/repositories/transaction_repository_test.dart test/unit/repositories/repository_exceptions_test.dart test/unit/controllers/transaction_form_controller_test.dart test/widget/features/transactions/transaction_form_screen_test.dart
```

Expected:
- FAIL on mismatch-exception assumptions and missing currency UI/state

### Task 8: Implement the new transaction currency state, repository behavior, and picker UI

**Files:**
- Modify: `lib/features/transactions/transaction_form_state.dart`
- Modify: `lib/features/transactions/transaction_form_controller.dart`
- Modify: `lib/features/transactions/transaction_form_screen.dart`
- Modify: `lib/features/transactions/transactions_providers.dart`
- Modify: `lib/features/transactions/widgets/account_selector_tile.dart`
- Modify: `lib/features/transactions/widgets/amount_display.dart`
- Create: `lib/features/transactions/widgets/currency_selector_tile.dart`
- Create: `lib/features/transactions/widgets/currency_picker_sheet.dart`
- Modify: `lib/data/repositories/transaction_repository.dart`
- Modify: `lib/data/repositories/repository_exceptions.dart`

**Why this task exists:** The state shape, controller comments, repository invariants, and form UI all still assume account currency is the only valid transaction currency.

- [ ] **Step 1: Add `currencyTouched` to `TransactionFormState.data` and regenerate later**

Update `lib/features/transactions/transaction_form_state.dart`:

```dart
required bool currencyTouched,
```

Also update the `displayCurrency` doc comment so it says user-controlled transaction currency, not an account mirror.

- [ ] **Step 2: Remove the stale account-currency invariant commentary from `TransactionFormController`**

Delete or rewrite the header comments in `lib/features/transactions/transaction_form_controller.dart` that still say:

```dart
// tx.currency = selectedAccount.currency on save
// avoids TransactionAccountCurrencyMismatchException
```

The spec explicitly invalidates that comment.

- [ ] **Step 3: Implement the new controller behavior**

Make these changes in `lib/features/transactions/transaction_form_controller.dart`:

```dart
void selectCurrency(Currency currency, {bool clearAmountOnChange = false}) { ... }

void selectAccount(Account account, {bool clearAmountOnReseed = false}) { ... }
```

Rules to encode:
- add/duplicate hydrate with `currencyTouched: false`
- edit hydrate with stored `displayCurrency` and `currencyTouched: true`
- account change re-seeds `displayCurrency` only while `currencyTouched == false`
- any currency change that would reinterpret a non-zero amount requires the explicit clear flag
- successful manual currency change flips `currencyTouched` to `true`
- `save()` uses `state.displayCurrency!`

- [ ] **Step 4: Remove the mismatch guard from the repository and delete the exception type**

In `lib/data/repositories/transaction_repository.dart`, delete the `AccountDao` lookup and the `TransactionAccountCurrencyMismatchException` branch entirely.

In `lib/data/repositories/repository_exceptions.dart`, delete the class definition.

After the cleanup, this search must return nothing:

```bash
rg "TransactionAccountCurrencyMismatchException" lib test
```

- [ ] **Step 5: Add a transaction-specific currency picker and selector tile**

Create `lib/features/transactions/widgets/currency_selector_tile.dart` and `lib/features/transactions/widgets/currency_picker_sheet.dart`.

The new picker should:
- read from a new transactions-slice currency provider in `lib/features/transactions/transactions_providers.dart`
- list non-token currencies
- show `code` as the title and `currencyDisplayName(c, l10n)` as the subtitle
- include a search `TextField` that filters by code or localized name

Keep it transactions-local because it needs search, confirmation wiring, and the transaction form's selection contract.

- [ ] **Step 6: Insert the currency row into the form between account and date**

In `lib/features/transactions/transaction_form_screen.dart`, render:

```dart
CurrencySelectorTile(
  currency: state.displayCurrency,
  onTap: () => _onTapCurrencyTile(context, l10n, state, controller),
)
```

Use the same confirm dialog text from Task 2 when a non-zero amount would be cleared.

- [ ] **Step 7: Change the amount display to the new cleared-currency UX**

In `lib/features/transactions/widgets/amount_display.dart`:
- when `amountMinorUnits == 0` after a currency clear, show `l10n.txAmountPlaceholderInCurrency(code)` instead of a bare `0`

- [ ] **Step 8: Regenerate Freezed/Riverpod code for the state/controller changes**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected:
- `lib/features/transactions/transaction_form_state.freezed.dart`
- `lib/features/transactions/transaction_form_controller.g.dart`

update successfully.

- [ ] **Step 9: Re-run the transaction/repository test slice until it passes**

Run:

```bash
flutter test test/unit/repositories/transaction_repository_test.dart test/unit/repositories/repository_exceptions_test.dart test/unit/controllers/transaction_form_controller_test.dart test/widget/features/transactions/transaction_form_screen_test.dart
```

Expected:
- PASS

- [ ] **Step 10: Commit the transaction-currency chunk**

```bash
git add lib/features/transactions/transaction_form_state.dart lib/features/transactions/transaction_form_controller.dart lib/features/transactions/transaction_form_screen.dart lib/features/transactions/transactions_providers.dart lib/features/transactions/widgets/account_selector_tile.dart lib/features/transactions/widgets/amount_display.dart lib/features/transactions/widgets/currency_selector_tile.dart lib/features/transactions/widgets/currency_picker_sheet.dart lib/data/repositories/transaction_repository.dart lib/data/repositories/repository_exceptions.dart test/unit/controllers/transaction_form_controller_test.dart test/widget/features/transactions/transaction_form_screen_test.dart test/unit/repositories/transaction_repository_test.dart test/unit/repositories/repository_exceptions_test.dart
git commit -m "feat(transactions): decouple currency from account"
```

## Chunk 5: Grouped Account Balances

### Task 9: Replace scalar balance tests with grouped-by-currency repository expectations

**Files:**
- Modify: `test/unit/repositories/account_repository_test.dart`
- Modify: `test/unit/controllers/accounts_controller_test.dart`
- Modify: `test/widget/features/accounts/accounts_screen_test.dart`

**Why this task exists:** The repository/controller/widget tests are still frozen around a single integer balance. The spec requires grouped output, zero-group suppression, and `+N more` rendering.

- [ ] **Step 1: Replace the `watchBalanceMinorUnits` test group with `watchBalanceByCurrency` coverage**

In `test/unit/repositories/account_repository_test.dart`, rename the group and replace the scalar assertions with map assertions such as:

```dart
test('own currency group includes opening balance plus same-currency net', () async {
  expect(await repo.watchBalanceByCurrency(id).first, {'USD': 8000});
});

test('foreign-currency transactions create separate groups without opening balance', () async {
  expect(await repo.watchBalanceByCurrency(id).first, {
    'USD': 10000,
    'JPY': -500,
  });
});

test('zero-value groups are suppressed', () async {
  expect(await repo.watchBalanceByCurrency(id).first, isNot(contains('JPY')));
});
```

Use the existing raw transaction helpers in this file. Do not add a second test harness.

- [ ] **Step 2: Rewrite the Accounts controller tests to expect grouped balances instead of `balanceMinorUnits`**

In `test/unit/controllers/accounts_controller_test.dart`:
- change the mocked per-account stream type from `StreamController<int>` to `StreamController<Map<String, int>>`
- rename the assertions to inspect grouped maps
- keep the default/archive/delete affordance coverage unchanged

- [ ] **Step 3: Rewrite the Accounts widget tests around grouped text output**

In `test/widget/features/accounts/accounts_screen_test.dart`, replace the scalar currency assertions with:

```dart
expect(find.text('USD: $123.45'), findsOneWidget);
expect(find.text('JPY: ¥500'), findsOneWidget);
expect(find.text('+2 more'), findsOneWidget);
```

Also add a 2x text-scale case for a multi-line mixed-currency tile.

- [ ] **Step 4: Run the Accounts test slice to verify the failures are the expected shape mismatch**

Run:

```bash
flutter test test/unit/repositories/account_repository_test.dart test/unit/controllers/accounts_controller_test.dart test/widget/features/accounts/accounts_screen_test.dart
```

Expected:
- FAIL on missing `watchBalanceByCurrency` API and stale scalar view model fields

### Task 10: Implement `watchBalanceByCurrency` and migrate the Accounts slice

**Files:**
- Modify: `lib/data/repositories/account_repository.dart`
- Modify: `lib/features/accounts/accounts_controller.dart`
- Modify: `lib/features/accounts/accounts_state.dart`
- Modify: `lib/features/accounts/accounts_providers.dart`
- Modify: `lib/features/accounts/accounts_screen.dart`
- Modify: `lib/features/accounts/widgets/account_tile.dart`

**Why this task exists:** The repo and Accounts slice still assume every account has exactly one tracked display balance.

- [ ] **Step 1: Add the new repository contract and remove the old production API**

Update `lib/data/repositories/account_repository.dart`:

```dart
Stream<Map<String, int>> watchBalanceByCurrency(int accountId);
```

Then remove `watchBalanceMinorUnits(...)` after the controller migration is done and there are no production callers left.

- [ ] **Step 2: Implement grouped SQL in `DriftAccountRepository`**

Use one grouped query over the account's transactions, then merge opening balance into the account's own currency group only:

```dart
SELECT t.currency AS code,
       SUM(CASE c.type
             WHEN 'income' THEN t.amount_minor_units
             WHEN 'expense' THEN -t.amount_minor_units
           END) AS net
FROM transactions t
JOIN categories c ON c.id = t.category_id
WHERE t.account_id = ?
GROUP BY t.currency
```

In Dart:
- seed the map from SQL rows
- add `opening_balance_minor_units` only to `account.currency.code`
- remove any zero-valued entries before emitting
- emit `{}` for missing accounts instead of throwing

- [ ] **Step 3: Change `AccountsState` to carry grouped balances**

Replace the scalar field in `lib/features/accounts/accounts_state.dart`:

```dart
required Map<String, int> balancesByCurrency,
```

Keep the rest of `AccountWithBalance` intact.

- [ ] **Step 4: Update `AccountsController` to subscribe to grouped balance streams**

In `lib/features/accounts/accounts_controller.dart`:
- change `_balanceSubs` to `Map<int, StreamSubscription<Map<String, int>>>`
- change `_balances` to `Map<int, Map<String, int>>`
- subscribe with `watchBalanceByCurrency(a.id)`
- emit `AccountWithBalance(balancesByCurrency: ...)`

- [ ] **Step 5: Add currency metadata lookup support in the Accounts slice**

In `lib/features/accounts/accounts_providers.dart`, add a read-only lookup like:

```dart
final currenciesByCodeProvider = StreamProvider.autoDispose<Map<String, Currency>>((ref) {
  final repo = ref.watch(currencyRepositoryProvider);
  return repo.watchAll(includeTokens: true).map((rows) => {for (final c in rows) c.code: c});
});
```

Then use it from `lib/features/accounts/accounts_screen.dart` / `lib/features/accounts/widgets/account_tile.dart` so the tile can format each group correctly.

- [ ] **Step 6: Render single-line vs multi-line account balances truthfully**

In `lib/features/accounts/widgets/account_tile.dart`:
- if there is one group, render one formatted line
- if there are two or three groups, render one plain-text line per group as `[code]: [formatted amount]`
- if there are more than three groups, render the first two plus `l10n.accountsBalanceMore(count)`
- let the row grow vertically under 2x text scale; do not force ellipsis on the balance column

- [ ] **Step 7: Re-run the Accounts test slice until all grouped-balance assertions pass**

Run:

```bash
flutter test test/unit/repositories/account_repository_test.dart test/unit/controllers/accounts_controller_test.dart test/widget/features/accounts/accounts_screen_test.dart
```

Expected:
- PASS

- [ ] **Step 8: Commit the grouped-balance chunk**

```bash
git add lib/data/repositories/account_repository.dart lib/features/accounts/accounts_controller.dart lib/features/accounts/accounts_state.dart lib/features/accounts/accounts_providers.dart lib/features/accounts/accounts_screen.dart lib/features/accounts/widgets/account_tile.dart test/unit/repositories/account_repository_test.dart test/unit/controllers/accounts_controller_test.dart test/widget/features/accounts/accounts_screen_test.dart
git commit -m "feat(accounts): group balances by currency"
```

## Chunk 6: PRD Alignment, Integration Coverage, And Final Verification

### Task 11: Update `PRD.md` to match the approved Home and currency rules

**Files:**
- Modify: `PRD.md`

**Why this task exists:** The current product doc still says Home steps through days-with-activity and transaction currency is inherited from the selected account.

- [ ] **Step 1: Update the MVP/Phase 2 multi-currency policy section**

Edit the currency paragraphs around:
- `PRD.md:264`
- `PRD.md:302-304`
- `PRD.md:361-364`

Make the document say:
- `transactions.currency` is the MVP source of truth
- `accounts.currency` is the opening-balance/default currency only
- grouped-by-original-currency summaries remain the MVP behavior
- Phase 2 adds fetched FX rates and default-currency totals as additive display data

- [ ] **Step 2: Update the Home screen description and screen states**

Edit the sections around:
- `PRD.md:678-679`
- `PRD.md:700-702`
- `PRD.md:782-795`

Make them explicitly say:
- Home browses real calendar days, including empty days
- gap days render a transaction-style `No transaction` card
- summary strip follows `selectedDay`
- Jump to today appears when `selectedDay != today`
- next is capped at today and prev is capped at 1900

- [ ] **Step 3: Update Add/Edit Transaction and Accounts copy in `PRD.md`**

Edit the sections around:
- `PRD.md:679`
- `PRD.md:687-697`
- `PRD.md:680`

Make them explicitly say:
- transaction currency is a visible form field in add/edit/duplicate
- currency seeds from the selected account default but is independently overridable
- mixed-currency accounts render grouped plain-text lines plus `+N more`

- [ ] **Step 4: Update the Phase 2 `exchange_rates` description to match the spec wording**

Edit `PRD.md:368-383` so it says:
- the logical shape is `exchange_rates(date, base_code, quote_code, numerator, denominator)`
- rates are joined at read time
- transaction rows are never rewritten retroactively

- [ ] **Step 5: Commit the doc-only update**

```bash
git add PRD.md
git commit -m "docs: align PRD with home and currency rules"
```

### Task 12: Add the end-to-end regression coverage and run the full verification set

**Files:**
- Modify: `test/integration/transaction_mutation_flow_test.dart`
- Modify: `test/integration/multi_currency_flow_test.dart`

**Why this task exists:** The existing integration tests prove Home/form wiring, but they do not yet cover cross-currency transactions on the same account or the gap-day-to-save flow required by the spec.

- [ ] **Step 1: Add a gap-day add flow integration test**

In `test/integration/transaction_mutation_flow_test.dart`, add a case that:
- boots into Home on a selected gap day
- opens Add from that day
- saves a transaction
- returns to Home with the same day pinned and the empty card replaced by a transaction tile

- [ ] **Step 2: Add a same-account cross-currency integration test**

In `test/integration/multi_currency_flow_test.dart`, add a case that:
- uses one seeded USD account
- saves a USD transaction and a JPY transaction against that same account
- verifies the Home summary still renders separate currency groups
- verifies the account row renders grouped balances instead of a fake scalar total

- [ ] **Step 3: Regenerate code one final time if any annotated files changed during the integration pass**

Run only if needed:

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Run the full required verification sequence in repo order**

Run:

```bash
dart format .
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
dart run import_lint
flutter analyze
flutter test test/unit/controllers/home_controller_test.dart
flutter test test/widget/features/home/home_screen_test.dart
flutter test test/unit/controllers/transaction_form_controller_test.dart
flutter test test/widget/features/transactions/transaction_form_screen_test.dart
flutter test test/unit/repositories/transaction_repository_test.dart
flutter test test/unit/repositories/account_repository_test.dart
flutter test test/unit/controllers/accounts_controller_test.dart
flutter test test/widget/features/accounts/accounts_screen_test.dart
flutter test test/integration/transaction_mutation_flow_test.dart
flutter test test/integration/multi_currency_flow_test.dart
flutter test
```

Expected:
- every command exits 0
- `flutter analyze` ends with `No issues found!`
- `flutter test` ends with all tests passing

- [ ] **Step 5: Do a final stale-contract grep sweep**

Run:

```bash
rg "watchBalanceMinorUnits|TransactionAccountCurrencyMismatchException|No transactions on \{date\}|No transactions on this day|DateTime\(9999, 12, 31\)" lib test PRD.md
```

Expected:
- no output for stale contracts that should have been removed
- if anything still matches, fix it before the final commit

- [ ] **Step 6: Create the final integration/verification commit**

```bash
git add test/integration/transaction_mutation_flow_test.dart test/integration/multi_currency_flow_test.dart
git commit -m "test: cover home gap days and mixed-currency flows"
```

- [ ] **Step 7: Capture the final worktree status for handoff**

Run:

```bash
git status --short
```

Expected:
- no uncommitted tracked changes
- only intentionally untracked local artifacts, if any

Plan complete and saved to `docs/superpowers/plans/2026-04-28-home-transaction-currency.md`. Ready to execute?
