# Analysis Tab And Settings-Owned Account Management — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the Accounts tab to Analysis, move account management into Settings > Manage accounts, make shopping list a Home-owned flow, and update documentation.

**Architecture:** Information-architecture refactor only — no Drift schema or repository changes. The middle shell destination changes from `/accounts` (AccountsScreen) to `/analysis` (AnalysisScreen placeholder). Account management relocates into a Settings-owned adaptive sheet/dialog (`Manage accounts`). Shopping list moves from the Accounts branch to the Home branch. All in-repo `/accounts*` route callers migrate in lockstep.

**Tech Stack:** Flutter, Riverpod, go_router, Drift, flutter_slidable, flutter_secure_storage (unchanged), ARB localization

---

## File Structure

### New Files
| File                                                      | Responsibility                                                                                                                                                             |
|-----------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `lib/features/analysis/analysis_screen.dart`              | Phase 2 placeholder screen for the `/analysis` route                                                                                                                       |
| `lib/features/accounts/widgets/manage_accounts_body.dart` | Relocated private classes from `accounts_screen.dart` (`_AccountsBody`, `_AccountTileWithLookups`, `_AccountListCard`) — body content for the Manage accounts sheet/dialog |

### Renamed Files
| Old Path                                                          | New Path                                                   | Responsibility                                                                                    |
|-------------------------------------------------------------------|------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| `lib/features/settings/widgets/default_account_tile.dart`         | `lib/features/settings/widgets/manage_accounts_tile.dart`  | Settings list row — renamed from "Default account" to "Manage accounts" with count-aware subtitle |
| `lib/features/settings/widgets/default_account_picker_sheet.dart` | `lib/features/settings/widgets/manage_accounts_sheet.dart` | Entry API (`showManageAccountsSheet`) — adaptive sheet/dialog hosting the body                    |

### Modified Files
| File                                                          | Changes                                                                                                                                                   |
|---------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `lib/app/router.dart`                                         | Replace `/accounts` branch with `/analysis`; add `/home/shopping-list*` routes; add `/settings/manage-accounts/*` routes; remove old `/accounts/*` routes |
| `lib/app/widgets/adaptive_shell.dart`                         | Change middle tab label from `navAccounts` to `navAnalysis`; change icon from `account_balance_wallet` to `analytics_outlined`                            |
| `lib/features/home/home_screen.dart`                          | Change shopping-cart FAB from `context.go('/accounts/shopping-list')` to `context.push('/home/shopping-list')`                                            |
| `lib/features/shopping_list/shopping_list_screen.dart`        | Change row-tap from `/accounts/shopping-list/$id` to `/home/shopping-list/$id`                                                                            |
| `lib/features/transactions/transaction_form_screen.dart`      | Change recovery flow from `/accounts/new` to `/settings/manage-accounts/new`                                                                              |
| `lib/features/transactions/widgets/account_picker_sheet.dart` | Change create-account from `/accounts/new` to `/settings/manage-accounts/new`                                                                             |
| `lib/features/accounts/account_form_screen.dart`              | Change two fallback sites from `context.go('/accounts')` to `context.go('/settings')`                                                                     |
| `lib/features/accounts/widgets/account_tile.dart`             | Add optional `onEdit` callback; replace archived-row `SizedBox.shrink()` with `PopupMenuButton` containing `Edit`                                         |
| `lib/features/settings/settings_screen.dart`                  | Replace `DefaultAccountTile` import/usage with `ManageAccountsTile`                                                                                       |
| `l10n/app_en.arb`                                             | Add new keys; change `navAccounts` → `navAnalysis`                                                                                                        |
| `l10n/app_zh.arb`                                             | Mirror new keys                                                                                                                                           |
| `l10n/app_zh_CN.arb`                                          | Mirror new keys                                                                                                                                           |
| `l10n/app_zh_TW.arb`                                          | Mirror new keys                                                                                                                                           |
| `PRD.md`                                                      | Update all references from Accounts to Analysis/Manage accounts                                                                                           |
| `README.md`                                                   | Update user-facing structure description                                                                                                                  |

### Deleted Files
| File                                                                         | Reason                                                                 |
|------------------------------------------------------------------------------|------------------------------------------------------------------------|
| `lib/features/accounts/accounts_screen.dart`                                 | Replaced by `manage_accounts_body.dart` + `manage_accounts_sheet.dart` |
| `lib/features/shopping_list/widgets/shopping_list_card.dart`                 | Was only used by deleted `accounts_screen.dart`; no other callers      |
| `test/widget/features/shopping_list/shopping_list_card_test.dart`            | Tests deleted widget                                                   |
| `test/widget/features/shopping_list/shopping_list_card_add_button_test.dart` | Tests deleted widget                                                   |

### Test Files
| File                                                                | Changes                                                                                                   |
|---------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| `test/unit/app/router_test.dart`                                    | Migrate all `/accounts*` assertions to `/analysis`, `/settings/manage-accounts/*`, `/home/shopping-list*` |
| `test/widget/features/accounts/accounts_screen_test.dart`           | Migrate to test `ManageAccountsBody` / `ManageAccountsSheet` instead of deleted `AccountsScreen`          |
| `test/widget/features/home/home_shopping_list_fab_test.dart`        | Change expected route from `/accounts/shopping-list` to `/home/shopping-list`                             |
| New: `test/widget/features/analysis/analysis_screen_test.dart`      | Test AnalysisScreen renders placeholder                                                                   |
| New: `test/widget/features/accounts/manage_accounts_body_test.dart` | Test ManageAccountsBody rendering and interactions                                                        |
| New: `test/widget/features/accounts/account_tile_on_edit_test.dart` | Test onEdit callback for active and archived rows                                                         |

---

## Chunk 1: Localization And Analysis Screen

### Task 1: Add new l10n keys and rename navAccounts → navAnalysis

**Files:**
- Modify: `l10n/app_en.arb`
- Modify: `l10n/app_zh.arb`
- Modify: `l10n/app_zh_CN.arb`
- Modify: `l10n/app_zh_TW.arb`
- Modify: `lib/l10n/app_localizations.dart` (generated — will regenerate)
- Modify: `lib/l10n/app_localizations_en.dart` (generated — will regenerate)
- Modify: `lib/l10n/app_localizations_zh.dart` (generated — will regenerate)

- [ ] **Step 1: Read current l10n files to understand structure**

Read `l10n/app_en.arb`, `l10n/app_zh.arb`, `l10n/app_zh_CN.arb`, `l10n/app_zh_TW.arb` to understand existing keys and structure.

- [ ] **Step 2: Rename `navAccounts` to `navAnalysis` in app_en.arb**

In `l10n/app_en.arb`, change:
```json
"navAccounts": "Accounts",
"@navAccounts": {
  "description": "PRD 656. Bottom-nav tab 2 label."
}
```
to:
```json
"navAnalysis": "Analysis",
"@navAnalysis": {
  "description": "PRD 656. Bottom-nav tab 2 label. Renamed from Accounts to Analysis."
}
```

- [ ] **Step 3: Add new l10n keys to app_en.arb**

Add these keys before the closing `}` in `l10n/app_en.arb`:

```json
"manageAccountsTitle": "Manage accounts",
"@manageAccountsTitle": {
  "description": "Title for the Manage accounts surface (sheet/dialog) and the Settings entry-point row."
},
"manageAccountsCreateCta": "Create account",
"@manageAccountsCreateCta": {
  "description": "CTA button inside the Manage accounts surface to create a new account."
},
"manageAccountsSetDefaultSuccess": "{name} is now the default account.",
"@manageAccountsSetDefaultSuccess": {
  "description": "SnackBar shown after successfully setting an account as default.",
  "placeholders": {
    "name": {"type": "String"}
  }
},
"manageAccountsSetDefaultFailed": "Couldn't change default account. Try again.",
"@manageAccountsSetDefaultFailed": {
  "description": "SnackBar shown when setting default account fails."
},
"manageAccountsLoadError": "Couldn't load accounts.",
"@manageAccountsLoadError": {
  "description": "Inline error placeholder shown when the Manage accounts body fails to load."
},
"manageAccountsTileSubtitleMore": "{count, plural, =1{ +1 more} other{ +{count} more}}",
"@manageAccountsTileSubtitleMore": {
  "description": "Settings tile subtitle suffix when N≥2 active accounts exist. Concatenated after the default name.",
  "placeholders": {
    "count": {"type": "int"}
  }
},
"manageAccountsTileSubtitleAddCta": "Add an account",
"@manageAccountsTileSubtitleAddCta": {
  "description": "Settings tile subtitle when zero active accounts exist."
},
"manageAccountsBodyEmpty": "No accounts yet. Create one to get started.",
"@manageAccountsBodyEmpty": {
  "description": "Empty-state body text inside the Manage accounts surface when no accounts exist."
},
"analysisPlaceholderTitle": "Analysis is coming in Phase 2",
"@analysisPlaceholderTitle": {
  "description": "Title for the Analysis screen empty-state placeholder."
},
"analysisPlaceholderBody": "Charts and summaries will appear here once Phase 2 lands.",
"@analysisPlaceholderBody": {
  "description": "Body copy for the Analysis screen empty-state placeholder."
}
```

- [ ] **Step 4: Mirror changes to app_zh.arb, app_zh_CN.arb, app_zh_TW.arb**

For `app_zh.arb` (fallback shim — bare `zh` resolves to English at runtime), add the same keys with English values (this file is a shim per CLAUDE.md).

For `app_zh_CN.arb`:
```json
"navAnalysis": "分析",
"manageAccountsTitle": "管理账户",
"manageAccountsCreateCta": "创建账户",
"manageAccountsSetDefaultSuccess": "{name} 已设为默认账户。",
"manageAccountsSetDefaultFailed": "无法更改默认账户，请重试。",
"manageAccountsLoadError": "无法加载账户。",
"manageAccountsTileSubtitleMore": "{count, plural, =1{ +1 个} other{ +{count} 个}}",
"manageAccountsTileSubtitleAddCta": "添加账户",
"manageAccountsBodyEmpty": "还没有账户，创建一个开始吧。",
"analysisPlaceholderTitle": "分析功能将在第二阶段推出",
"analysisPlaceholderBody": "图表和摘要将在第二阶段上线后显示。"
```

For `app_zh_TW.arb`:
```json
"navAnalysis": "分析",
"manageAccountsTitle": "管理帳戶",
"manageAccountsCreateCta": "建立帳戶",
"manageAccountsSetDefaultSuccess": "{name} 已設為預設帳戶。",
"manageAccountsSetDefaultFailed": "無法變更預設帳戶，請重試。",
"manageAccountsLoadError": "無法載入帳戶。",
"manageAccountsTileSubtitleMore": "{count, plural, =1{ +1 個} other{ +{count} 個}}",
"manageAccountsTileSubtitleAddCta": "新增帳戶",
"manageAccountsBodyEmpty": "還沒有帳戶，建立一個開始吧。",
"analysisPlaceholderTitle": "分析功能將在第二階段推出",
"analysisPlaceholderBody": "圖表和摘要將在第二階段上線後顯示。"
```

- [ ] **Step 5: Run Flutter l10n codegen**

```bash
flutter gen-l10n
```

Verify `lib/l10n/app_localizations.dart` now contains `navAnalysis`, all `manageAccounts*` keys, and `analysisPlaceholder*` keys.

- [ ] **Step 6: Fix any broken references to `navAccounts`**

```bash
grep -rn "navAccounts" lib/
```

Replace any remaining references to `navAccounts` with `navAnalysis`. Expected: only `adaptive_shell.dart` and generated files reference it.

- [ ] **Step 7: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS (may have existing warnings but no new errors).

- [ ] **Step 8: Commit**

```bash
git add l10n/ lib/l10n/ lib/app/widgets/adaptive_shell.dart
git commit -m "feat(l10n): add manage-accounts and analysis keys, rename navAccounts to navAnalysis"
```

---

### Task 2: Update AdaptiveShell label and icon

**Files:**
- Modify: `lib/app/widgets/adaptive_shell.dart:44,61`

- [ ] **Step 1: Change the middle tab label and icon**

In `lib/app/widgets/adaptive_shell.dart`, change both the NavigationRail and NavigationBar destinations for the middle tab:

Replace:
```dart
NavigationRailDestination(
  icon: const Icon(Icons.account_balance_wallet),
  label: Text(l10n.navAccounts),
),
```
with:
```dart
NavigationRailDestination(
  icon: const Icon(Icons.analytics_outlined),
  label: Text(l10n.navAnalysis),
),
```

And replace:
```dart
NavigationDestination(
  icon: const Icon(Icons.account_balance_wallet),
  label: l10n.navAccounts,
),
```
with:
```dart
NavigationDestination(
  icon: const Icon(Icons.analytics_outlined),
  label: l10n.navAnalysis,
),
```

- [ ] **Step 2: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/app/widgets/adaptive_shell.dart
git commit -m "feat(ui): rename middle tab from Accounts to Analysis with analytics icon"
```

---

### Task 3: Create AnalysisScreen

**Files:**
- Create: `lib/features/analysis/analysis_screen.dart`

- [ ] **Step 1: Create the AnalysisScreen**

Create `lib/features/analysis/analysis_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAnalysis)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.analysisPlaceholderTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.analysisPlaceholderBody,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Write a widget test for AnalysisScreen**

Create `test/widget/features/analysis/analysis_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ledgerly/features/analysis/analysis_screen.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Widget _wrap({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('AN01: AnalysisScreen renders placeholder title and body', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(child: const AnalysisScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Analysis is coming in Phase 2'), findsOneWidget);
    expect(
      find.text('Charts and summaries will appear here once Phase 2 lands.'),
      findsOneWidget,
    );
  });

  testWidgets('AN02: AnalysisScreen AppBar title says Analysis', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(child: const AnalysisScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Analysis'), findsWidgets); // AppBar title + nav label
  });

  testWidgets('AN03: AnalysisScreen has no FAB', (tester) async {
    await tester.pumpWidget(_wrap(child: const AnalysisScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
```

- [ ] **Step 3: Run the test**

```bash
dart format . && flutter test test/widget/features/analysis/analysis_screen_test.dart -v
```

Expected: PASS (all 3 tests).

- [ ] **Step 4: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/analysis/analysis_screen.dart test/widget/features/analysis/analysis_screen_test.dart
git commit -m "feat(analysis): add AnalysisScreen with Phase 2 placeholder"
```

---

## Chunk 2: AccountTile And Manage Accounts Body

### Task 4: Add `onEdit` callback to AccountTile

**Files:**
- Modify: `lib/features/accounts/widgets/account_tile.dart`
- Test: `test/widget/features/accounts/account_tile_on_edit_test.dart`

- [ ] **Step 1: Add optional `onEdit` callback to AccountTile constructor**

In `lib/features/accounts/widgets/account_tile.dart`, add the `onEdit` parameter:

```dart
class AccountTile extends ConsumerWidget {
  const AccountTile({
    super.key,
    required this.view,
    required this.isDefault,
    required this.locale,
    required this.accountTypeLabel,
    required this.onTap,
    required this.onSetDefault,
    required this.onArchive,
    required this.onDelete,
    required this.onArchiveBlocked,
    this.onEdit,  // ADD THIS
  });

  // ... existing fields ...
  final VoidCallback? onEdit;  // ADD THIS
```

- [ ] **Step 2: Pass `onEdit` to `_TrailingActions`**

In the `build` method, find where `_TrailingActions` is constructed and pass `onEdit`:

```dart
_TrailingActions(
  view: view,
  isDefault: isDefault,
  onSetDefault: onSetDefault,
  onArchive: onArchive,
  onDelete: onDelete,
  onArchiveBlocked: onArchiveBlocked,
  onEdit: onEdit,  // ADD THIS
),
```

- [ ] **Step 3: Update `_TrailingActions` to accept and use `onEdit`**

In `_TrailingActions`, add the `onEdit` field and update the build method:

```dart
class _TrailingActions extends StatelessWidget {
  const _TrailingActions({
    required this.view,
    required this.isDefault,
    required this.onSetDefault,
    required this.onArchive,
    required this.onDelete,
    required this.onArchiveBlocked,
    this.onEdit,  // ADD THIS
  });

  // ... existing fields ...
  final VoidCallback? onEdit;  // ADD THIS
```

Replace the archived-row early return and add `Edit` to active rows:

```dart
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a = view.account;

    // Archived rows: only show Edit option
    if (a.isArchived) {
      if (onEdit == null) return const SizedBox.shrink();
      return PopupMenuButton<_RowAction>(
        key: ValueKey('accountTile:${a.id}:menu'),
        icon: const Icon(Icons.more_vert),
        onSelected: (action) {
          if (action == _RowAction.edit) onEdit!();
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: _RowAction.edit,
            child: Text(l10n.homeEditAction),
          ),
        ],
      );
    }

    // Active rows: existing behavior + Edit option
    return PopupMenuButton<_RowAction>(
      key: ValueKey('accountTile:${a.id}:menu'),
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case _RowAction.edit:
            onEdit?.call();
          case _RowAction.setDefault:
            onSetDefault();
          case _RowAction.archive:
            if (view.affordance == AccountRowAffordance.archiveBlocked) {
              onArchiveBlocked();
            } else {
              onArchive();
            }
          case _RowAction.delete:
            onDelete();
        }
      },
      itemBuilder: (ctx) => [
        if (onEdit != null)
          PopupMenuItem(
            value: _RowAction.edit,
            child: Text(l10n.homeEditAction),
          ),
        if (!isDefault)
          PopupMenuItem(
            value: _RowAction.setDefault,
            child: Text(l10n.accountsSetDefaultAction),
          ),
        switch (view.affordance) {
          AccountRowAffordance.delete => PopupMenuItem(
            value: _RowAction.delete,
            child: Text(l10n.accountsDeleteAction),
          ),
          AccountRowAffordance.archive => PopupMenuItem(
            value: _RowAction.archive,
            child: Text(l10n.accountsArchiveAction),
          ),
          AccountRowAffordance.archiveBlocked => PopupMenuItem(
            value: _RowAction.archive,
            child: Text(l10n.accountsArchiveAction),
          ),
        },
      ],
    );
  }
```

- [ ] **Step 4: Add `_RowAction.edit` to the enum**

Find the `_RowAction` enum in the file and add `edit`:

```dart
enum _RowAction { edit, setDefault, archive, delete }
```

- [ ] **Step 5: Write widget tests for onEdit**

Create `test/widget/features/accounts/account_tile_on_edit_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/features/accounts/accounts_state.dart';
import 'package:ledgerly/features/accounts/widgets/account_tile.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockCurrencyRepo extends Mock implements CurrencyRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

Account _a({required int id, String name = 'Test', bool isArchived = false}) =>
    Account(
      id: id,
      name: name,
      accountTypeId: 1,
      currency: _usd,
      openingBalanceMinorUnits: 0,
      isArchived: isArchived,
    );

AccountWithBalance _wb(Account a) => AccountWithBalance(
  account: a,
  balancesByCurrency: const {},
  affordance: a.isArchived ? AccountRowAffordance.archive : AccountRowAffordance.archive,
);

Widget _wrap({required Widget child, required CurrencyRepository repo}) {
  return ProviderScope(
    overrides: [currencyRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const Currency(code: 'X', decimals: 2));
  });

  testWidgets('ATE01: active row overflow menu shows Edit when onEdit provided', (
    tester,
  ) async {
    final repo = _MockCurrencyRepo();
    when(() => repo.watchAll(includeTokens: any(named: 'includeTokens')))
        .thenAnswer((_) => Stream.value([_usd]));

    bool editCalled = false;
    await tester.pumpWidget(
      _wrap(
        repo: repo,
        child: AccountTile(
          view: _wb(_a(id: 1)),
          isDefault: false,
          locale: 'en',
          accountTypeLabel: 'Cash',
          onTap: () {},
          onSetDefault: () {},
          onArchive: () {},
          onDelete: () {},
          onArchiveBlocked: () {},
          onEdit: () => editCalled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('accountTile:1:menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();

    expect(editCalled, isTrue);
  });

  testWidgets('ATE02: archived row overflow menu shows Edit only', (
    tester,
  ) async {
    final repo = _MockCurrencyRepo();
    when(() => repo.watchAll(includeTokens: any(named: 'includeTokens')))
        .thenAnswer((_) => Stream.value([_usd]));

    bool editCalled = false;
    await tester.pumpWidget(
      _wrap(
        repo: repo,
        child: AccountTile(
          view: _wb(_a(id: 2, isArchived: true)),
          isDefault: false,
          locale: 'en',
          accountTypeLabel: 'Cash',
          onTap: () {},
          onSetDefault: () {},
          onArchive: () {},
          onDelete: () {},
          onArchiveBlocked: () {},
          onEdit: () => editCalled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('accountTile:2:menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(editCalled, isTrue);
    // No Set as default, Archive, or Delete should appear
    expect(find.text('Set as default'), findsNothing);
    expect(find.text('Archive'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('ATE03: archived row has no menu when onEdit is null', (
    tester,
  ) async {
    final repo = _MockCurrencyRepo();
    when(() => repo.watchAll(includeTokens: any(named: 'includeTokens')))
        .thenAnswer((_) => Stream.value([_usd]));

    await tester.pumpWidget(
      _wrap(
        repo: repo,
        child: AccountTile(
          view: _wb(_a(id: 3, isArchived: true)),
          isDefault: false,
          locale: 'en',
          accountTypeLabel: 'Cash',
          onTap: () {},
          onSetDefault: () {},
          onArchive: () {},
          onDelete: () {},
          onArchiveBlocked: () {},
          // onEdit is null (default)
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('accountTile:3:menu')), findsNothing);
  });

  testWidgets('ATE04: archived row Slidable panes are suppressed', (
    tester,
  ) async {
    final repo = _MockCurrencyRepo();
    when(() => repo.watchAll(includeTokens: any(named: 'includeTokens')))
        .thenAnswer((_) => Stream.value([_usd]));

    await tester.pumpWidget(
      _wrap(
        repo: repo,
        child: AccountTile(
          view: _wb(_a(id: 4, isArchived: true)),
          isDefault: false,
          locale: 'en',
          accountTypeLabel: 'Cash',
          onTap: () {},
          onSetDefault: () {},
          onArchive: () {},
          onDelete: () {},
          onArchiveBlocked: () {},
          onEdit: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Slidable should exist but with null action panes
    final slidable = tester.widget<Slidable>(find.byType(Slidable));
    expect(slidable.startActionPane, isNull);
    expect(slidable.endActionPane, isNull);
  });
}
```

Note: The test file imports `flutter_slidable` — add the import:
```dart
import 'package:flutter_slidable/flutter_slidable.dart';
```

- [ ] **Step 6: Run the tests**

```bash
dart format . && flutter test test/widget/features/accounts/account_tile_on_edit_test.dart -v
```

Expected: PASS.

- [ ] **Step 7: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/accounts/widgets/account_tile.dart test/widget/features/accounts/account_tile_on_edit_test.dart
git commit -m "feat(accounts): add onEdit callback to AccountTile, show Edit for archived rows"
```

---

### Task 5: Create ManageAccountsBody (relocated from AccountsScreen)

**Files:**
- Create: `lib/features/accounts/widgets/manage_accounts_body.dart`
- Modify: `lib/features/accounts/accounts_screen.dart` (will be deleted in Task 7)

- [ ] **Step 1: Read the full accounts_screen.dart to understand classes to relocate**

Read `lib/features/accounts/accounts_screen.dart` (368 lines). The classes to relocate are:
- `_AccountsBody` (~lines 68–155) — the main body with CustomScrollView
- `_AccountTileWithLookups` (~lines 157–243) — wraps AccountTile with provider lookups
- `_AccountListCard` (~lines 245–290) — the card container

Also relocate the `_ErrorSurface` class (~lines 292–305).

- [ ] **Step 2: Create manage_accounts_body.dart**

Create `lib/features/accounts/widgets/manage_accounts_body.dart`:

```dart
// Manage accounts body content.
//
// Relocated from the deleted `accounts_screen.dart`. Renders the account
// list inside the Manage accounts sheet/dialog. This is a package-internal
// widget — only `manage_accounts_sheet.dart` should import it.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/utils/box_shadow.dart';
import '../../../l10n/app_localizations.dart';
import '../accounts_controller.dart';
import '../accounts_providers.dart';
import '../accounts_state.dart';
import 'account_tile.dart';
import 'account_type_display.dart';

class ManageAccountsBody extends ConsumerWidget {
  const ManageAccountsBody({super.key, required this.data});

  final AccountsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    final allActiveIds = data.active
        .map((r) => r.account.id)
        .toList(growable: false);

    return SlidableAutoCloseBehavior(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active accounts section
          if (data.active.isNotEmpty)
            _AccountListCard(
              accounts: data.active,
              defaultAccountId: data.defaultAccountId,
              locale: locale,
              allActiveIds: allActiveIds,
            ),

          // Empty state
          if (data.active.isEmpty && data.archived.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.manageAccountsBodyEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),

          // Archived section
          if (data.archived.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    l10n.accountsArchivedSectionLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _AccountListCard(
                  accounts: data.archived,
                  defaultAccountId: null,
                  locale: locale,
                  allActiveIds: allActiveIds,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AccountTileWithLookups extends ConsumerWidget {
  const _AccountTileWithLookups({
    required this.view,
    required this.isDefault,
    required this.locale,
    required this.allActiveIds,
  });

  final AccountWithBalance view;
  final bool isDefault;
  final String locale;
  final List<int> allActiveIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final typeAsync = ref.watch(
      accountTypeByIdProvider(view.account.accountTypeId),
    );
    final typeLabel = typeAsync.maybeWhen(
      data: (t) => t == null ? '' : accountTypeDisplayName(t, l10n),
      orElse: () => '',
    );
    return AccountTile(
      view: view,
      isDefault: isDefault,
      locale: locale,
      accountTypeLabel: typeLabel,
      onTap: () => context.push('/settings/manage-accounts/${view.account.id}'),
      onEdit: () => context.push('/settings/manage-accounts/${view.account.id}'),
      onSetDefault: () => _onSetDefault(context, ref, view.account.id),
      onArchive: () => _onArchive(context, ref, view.account.id),
      onDelete: () => _onDelete(context, ref, view.account.id),
      onArchiveBlocked: () => _onArchiveBlocked(context),
    );
  }

  Future<void> _onSetDefault(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountsControllerProvider.notifier).setDefault(id);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.manageAccountsSetDefaultSuccess(''))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.manageAccountsSetDefaultFailed)),
          );
      }
    }
  }

  Future<void> _onArchive(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountsControllerProvider.notifier).archive(id);
    } on AccountsOperationException catch (e) {
      if (e.kind == AccountsOperationError.lastActiveAccount) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.accountsArchiveLastActiveBlocked)),
          );
        return;
      }
      if (e.kind == AccountsOperationError.defaultAccount) {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.accountsDeleteDefaultBlockedTitle),
            content: Text(l10n.accountsDeleteDefaultBlockedBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.commonCancel),
              ),
            ],
          ),
        );
        return;
      }
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(l10n.errorSnackbarGeneric)),
        );
      return;
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(l10n.errorSnackbarGeneric)),
        );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.accountsArchiveUndoSnackbar),
        action: SnackBarAction(
          label: l10n.commonUndo,
          onPressed: () => unawaited(
            ref.read(accountsControllerProvider.notifier).unarchive(id),
          ),
        ),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountsDeleteConfirmTitle),
        content: Text(l10n.accountsDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountsControllerProvider.notifier).delete(id);
    } on AccountsOperationException catch (e) {
      if (e.kind == AccountsOperationError.defaultAccount) {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.accountsDeleteDefaultBlockedTitle),
            content: Text(l10n.accountsDeleteDefaultBlockedBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.commonCancel),
              ),
            ],
          ),
        );
        return;
      }
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(l10n.errorSnackbarGeneric)),
        );
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(l10n.errorSnackbarGeneric)),
        );
    }
  }

  void _onArchiveBlocked(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(l10n.accountsArchiveLastActiveBlocked)),
      );
  }
}

class _AccountListCard extends StatelessWidget {
  const _AccountListCard({
    required this.accounts,
    required this.defaultAccountId,
    required this.locale,
    required this.allActiveIds,
  });

  final List<AccountWithBalance> accounts;
  final int? defaultAccountId;
  final String locale;
  final List<int> allActiveIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(homePageCardBorderRadius),
        boxShadow: [buildBoxShadow(homePageCardBorderRadius)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final view in accounts)
            _AccountTileWithLookups(
              view: view,
              isDefault: defaultAccountId == view.account.id,
              locale: locale,
              allActiveIds: allActiveIds,
            ),
        ],
      ),
    );
  }
}
```

**Important:** The `manageAccountsSetDefaultSuccess` key takes a `String name` parameter. You need to resolve the account name from the view. The `_AccountTileWithLookups` should pass the account name to the callback. Adjust `_onSetDefault` to accept the name:

```dart
// In _AccountTileWithLookups.build():
onSetDefault: () => _onSetDefault(context, ref, view.account.id, view.account.name),

// Updated signature:
Future<void> _onSetDefault(
  BuildContext context,
  WidgetRef ref,
  int id,
  String name,
) async {
  // ...
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.manageAccountsSetDefaultSuccess(name))),
  );
}
```

- [ ] **Step 3: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/accounts/widgets/manage_accounts_body.dart
git commit -m "feat(accounts): create ManageAccountsBody relocated from AccountsScreen"
```

---

### Task 6: Create ManageAccountsSheet (renamed from DefaultAccountPickerSheet)

**Files:**
- Create: `lib/features/settings/widgets/manage_accounts_sheet.dart`
- Create: `lib/features/settings/widgets/manage_accounts_tile.dart`

- [ ] **Step 1: Create manage_accounts_sheet.dart**

Create `lib/features/settings/widgets/manage_accounts_sheet.dart`:

```dart
// Manage accounts sheet — Settings-owned entry point.
//
// Adaptive: bottom sheet (<600dp) or dialog (>=600dp). Hosts
// ManageAccountsBody. The surface stays open when navigating to
// create/edit forms.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../accounts/accounts_controller.dart';
import '../../accounts/accounts_state.dart';
import '../../accounts/widgets/manage_accounts_body.dart';
import '../../../l10n/app_localizations.dart';

/// Opens the Manage accounts surface and returns when the user dismisses it.
Future<void> showManageAccountsSheet(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 600) {
    return showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          child: const _ManageAccountsContent(),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.75,
      child: const _ManageAccountsContent(),
    ),
  );
}

class _ManageAccountsContent extends ConsumerWidget {
  const _ManageAccountsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(accountsControllerProvider);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row with close button
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.manageAccountsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          // Body: loading | error | data
          Flexible(
            child: switch (state) {
              AsyncData<AccountsState>(value: final AccountsData data) =>
                ManageAccountsBody(data: data),
              AsyncData<AccountsState>(value: AccountsError()) ||
              AsyncError() =>
                _ErrorPlaceholder(
                  onRetry: () =>
                      ref.invalidate(accountsControllerProvider),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          // CTA pinned to bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.manageAccountsCreateCta),
                onPressed: () =>
                    context.push('/settings/manage-accounts/new'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.manageAccountsLoadError,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(l10n.shoppingListScreenRetry),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create manage_accounts_tile.dart**

Create `lib/features/settings/widgets/manage_accounts_tile.dart`:

```dart
// Manage accounts tile — Settings list row.
//
// Renamed from DefaultAccountTile. Shows "Manage accounts" with a
// count-aware subtitle that previews the default account name.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../settings_providers.dart';
import '../../accounts/accounts_controller.dart';
import '../../accounts/accounts_state.dart';
import 'manage_accounts_sheet.dart';

class ManageAccountsTile extends ConsumerWidget {
  const ManageAccountsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountsControllerProvider);
    final defaultAccountId = ref.watch(settingsControllerProvider).maybeWhen(
      data: (d) => d.defaultAccountId,
      orElse: () => null,
    );

    final subtitle = accountsAsync.maybeWhen(
      data: (state) {
        final data = state;
        if (data is! AccountsData) return '';
        if (data.active.isEmpty) return l10n.manageAccountsTileSubtitleAddCta;
        if (data.active.length == 1) return data.active.first.account.name;
        // N≥2: find default name + "+N more"
        final defaultName = data.active
            .where((r) => r.account.id == defaultAccountId)
            .map((r) => r.account.name)
            .firstOrNull ??
            data.active.first.account.name;
        return '$defaultName${l10n.manageAccountsTileSubtitleMore(data.active.length - 1)}';
      },
      orElse: () => '',
    );

    return ListTile(
      key: const ValueKey('settingsManageAccountsTile'),
      title: Text(l10n.manageAccountsTitle),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showManageAccountsSheet(context),
    );
  }
}
```

- [ ] **Step 3: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/widgets/manage_accounts_sheet.dart lib/features/settings/widgets/manage_accounts_tile.dart
git commit -m "feat(settings): create ManageAccountsSheet and ManageAccountsTile"
```

---

### Task 7: Update SettingsScreen to use ManageAccountsTile

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Replace DefaultAccountTile import and usage**

In `lib/features/settings/settings_screen.dart`:

Change the import:
```dart
import 'widgets/default_account_tile.dart';
```
to:
```dart
import 'widgets/manage_accounts_tile.dart';
```

Change the widget usage in the General section:
```dart
DefaultAccountTile(defaultAccountId: data.defaultAccountId),
```
to:
```dart
const ManageAccountsTile(),
```

- [ ] **Step 2: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat(settings): replace DefaultAccountTile with ManageAccountsTile"
```

---

## Chunk 3: Router Overhaul

### Task 8: Rewrite router.dart — replace /accounts branch with /analysis, add new routes

**Files:**
- Modify: `lib/app/router.dart`

- [ ] **Step 1: Read the full router.dart to understand current structure**

Read `lib/app/router.dart` (255 lines). Key structure:
- 3 StatefulShellBranch: `/home`, `/accounts`, `/settings`
- `/accounts` branch has: `AccountsScreen`, `/accounts/new`, `/accounts/shopping-list`, `/accounts/shopping-list/:itemId`, `/accounts/:id`

- [ ] **Step 2: Update imports**

Replace:
```dart
import '../features/accounts/accounts_screen.dart';
```
with:
```dart
import '../features/analysis/analysis_screen.dart';
import '../features/settings/widgets/manage_accounts_sheet.dart';
```

Keep the `AccountFormScreen` import — it's still used.

- [ ] **Step 3: Replace the middle branch**

Replace the entire second `StatefulShellBranch`:

```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/analysis',
      builder: (_, _) => const AnalysisScreen(),
    ),
  ],
),
```

- [ ] **Step 4: Add shopping-list routes under the Home branch**

Inside the `/home` route's `routes` list, add after `edit/:id`:

```dart
GoRoute(
  path: 'shopping-list',
  builder: (_, _) => const ShoppingListScreen(),
  routes: [
    GoRoute(
      path: ':itemId',
      redirect: (_, state) =>
          int.tryParse(state.pathParameters['itemId'] ?? '') == null
          ? '/home/shopping-list'
          : null,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (ctx, state) => _modalPage(
        state,
        _AdaptiveTransactionFormRoute(
          shoppingListItemId: int.parse(
            state.pathParameters['itemId']!,
          ),
        ),
        fullscreenDialog: true,
      ),
    ),
  ],
),
```

- [ ] **Step 5: Add manage-accounts routes under the Settings branch**

Inside the `/settings` route's `routes` list, add:

```dart
GoRoute(
  path: 'manage-accounts/new',
  parentNavigatorKey: _rootNavigatorKey,
  pageBuilder: (ctx, state) => _modalPage(
    state,
    const AccountFormScreen(),
    fullscreenDialog: true,
  ),
),
GoRoute(
  path: 'manage-accounts/:id',
  redirect: (_, state) =>
      int.tryParse(state.pathParameters['id'] ?? '') == null
      ? '/settings'
      : null,
  parentNavigatorKey: _rootNavigatorKey,
  pageBuilder: (ctx, state) => _modalPage(
    state,
    AccountFormScreen(
      accountId: int.parse(state.pathParameters['id']!),
    ),
    fullscreenDialog: true,
  ),
),
```

- [ ] **Step 6: Remove old /accounts routes**

Remove the entire old `/accounts` branch and its child routes. The `ShoppingListScreen` import should now point to the Home branch version.

- [ ] **Step 7: Add ShoppingListScreen import if not already present**

Ensure this import exists:
```dart
import '../features/shopping_list/shopping_list_screen.dart';
```

- [ ] **Step 8: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS. There may be import errors from other files still referencing old routes — those are fixed in Chunk 4.

- [ ] **Step 9: Run codegen**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 10: Commit**

```bash
git add lib/app/router.dart lib/app/router.g.dart
git commit -m "feat(router): replace /accounts branch with /analysis, add /home/shopping-list and /settings/manage-accounts routes"
```

---

## Chunk 4: Route Migration — Fix All Callers

### Task 9: Update HomeScreen shopping-cart FAB

**Files:**
- Modify: `lib/features/home/home_screen.dart:162`

- [ ] **Step 1: Change the shopping-cart FAB navigation**

In `lib/features/home/home_screen.dart`, line 162:

Replace:
```dart
onPressed: () => context.go('/accounts/shopping-list'),
```
with:
```dart
onPressed: () => context.push('/home/shopping-list'),
```

- [ ] **Step 2: Run dart format**

```bash
dart format lib/features/home/home_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/home_screen.dart
git commit -m "feat(home): change shopping-cart FAB to push /home/shopping-list"
```

---

### Task 10: Update ShoppingListScreen row-tap route

**Files:**
- Modify: `lib/features/shopping_list/shopping_list_screen.dart:112`

- [ ] **Step 1: Change the row-tap navigation**

In `lib/features/shopping_list/shopping_list_screen.dart`, line 112:

Replace:
```dart
'/accounts/shopping-list/$id',
```
with:
```dart
'/home/shopping-list/$id',
```

- [ ] **Step 2: Run dart format**

```bash
dart format lib/features/shopping_list/shopping_list_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/shopping_list/shopping_list_screen.dart
git commit -m "feat(shopping-list): change row-tap route to /home/shopping-list/:id"
```

---

### Task 11: Update TransactionFormScreen recovery flow

**Files:**
- Modify: `lib/features/transactions/transaction_form_screen.dart:694`

- [ ] **Step 1: Find the /accounts/new reference**

In `lib/features/transactions/transaction_form_screen.dart`, find the line that pushes `/accounts/new` in the recovery flow (around line 694):

```dart
context.push('/accounts/new').then(...)
```

Replace with:
```dart
context.push('/settings/manage-accounts/new').then(...)
```

- [ ] **Step 2: Run dart format**

```bash
dart format lib/features/transactions/transaction_form_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/transactions/transaction_form_screen.dart
git commit -m "feat(transactions): change create-account recovery route to /settings/manage-accounts/new"
```

---

### Task 12: Update AccountPickerSheet create-account route

**Files:**
- Modify: `lib/features/transactions/widgets/account_picker_sheet.dart:50`

- [ ] **Step 1: Change the create-account navigation**

In `lib/features/transactions/widgets/account_picker_sheet.dart`, line 50:

Replace:
```dart
final savedId = await context.push<int>('/accounts/new');
```
with:
```dart
final savedId = await context.push<int>('/settings/manage-accounts/new');
```

- [ ] **Step 2: Run dart format**

```bash
dart format lib/features/transactions/widgets/account_picker_sheet.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/transactions/widgets/account_picker_sheet.dart
git commit -m "feat(transactions): change create-account route to /settings/manage-accounts/new"
```

---

### Task 13: Update AccountFormScreen fallback routes

**Files:**
- Modify: `lib/features/accounts/account_form_screen.dart:150,306`

- [ ] **Step 1: Change the _NotFoundSurface fallback**

In `lib/features/accounts/account_form_screen.dart`, line 150:

Replace:
```dart
context.go('/accounts');
```
with:
```dart
context.go('/settings');
```

- [ ] **Step 2: Change the Cancel button fallback**

In the same file, line 306:

Replace:
```dart
context.go('/accounts');
```
with:
```dart
context.go('/settings');
```

- [ ] **Step 3: Verify no remaining /accounts references**

```bash
grep -n "/accounts" lib/features/accounts/account_form_screen.dart
```

Expected: zero matches outside import statements and generated code.

- [ ] **Step 4: Run dart format**

```bash
dart format lib/features/accounts/account_form_screen.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/accounts/account_form_screen.dart
git commit -m "feat(accounts): change form fallback routes from /accounts to /settings"
```

---

### Task 14: Delete old AccountsScreen, ShoppingListCard, and their tests

**Files:**
- Delete: `lib/features/accounts/accounts_screen.dart`
- Delete: `lib/features/shopping_list/widgets/shopping_list_card.dart`
- Delete: `test/widget/features/shopping_list/shopping_list_card_test.dart`
- Delete: `test/widget/features/shopping_list/shopping_list_card_add_button_test.dart`

- [ ] **Step 1: Verify no remaining imports of deleted files**

```bash
grep -rn "accounts_screen.dart\|shopping_list_card.dart" lib/ test/
```

Expected: zero matches. If any file still imports `accounts_screen.dart`, update it to import `manage_accounts_body.dart` or `manage_accounts_sheet.dart` instead.

- [ ] **Step 2: Delete the files**

```bash
rm lib/features/accounts/accounts_screen.dart
rm lib/features/shopping_list/widgets/shopping_list_card.dart
rm test/widget/features/shopping_list/shopping_list_card_test.dart
rm test/widget/features/shopping_list/shopping_list_card_add_button_test.dart
```

- [ ] **Step 3: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS. Fix any remaining import errors.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: delete AccountsScreen, ShoppingListCard, and their tests"
```

---

## Chunk 5: Test Migration

### Task 15: Update router_test.dart

**Files:**
- Modify: `test/unit/app/router_test.dart`

- [ ] **Step 1: Update imports**

Replace:
```dart
import 'package:ledgerly/features/accounts/accounts_screen.dart';
```
with:
```dart
import 'package:ledgerly/features/analysis/analysis_screen.dart';
```

Keep the `AccountFormScreen` and `ShoppingListScreen` imports.

- [ ] **Step 2: Update /accounts/new test to /settings/manage-accounts/new**

Replace the test `'accounts/new uses a root modal route and renders the form'`:

Change:
```dart
router.go('/accounts/new');
```
to:
```dart
router.go('/settings/manage-accounts/new');
```

Update assertions:
```dart
expect(leaf.matchedLocation, '/settings/manage-accounts/new');
expect(find.byType(AccountFormScreen), findsOneWidget);
expect(find.byType(AnalysisScreen), findsNothing);
```

- [ ] **Step 3: Update /accounts/:id invalid id test**

Replace the test `'accounts/:id rejects invalid ids safely'`:

Change:
```dart
router.go('/accounts/not-a-number');
```
to:
```dart
router.go('/settings/manage-accounts/not-a-number');
```

Update assertions:
```dart
expect(leaf.matchedLocation, '/settings');
expect(find.byType(AnalysisScreen), findsNothing);
```

- [ ] **Step 4: Update RT01 — shopping-list renders ShoppingListScreen**

Change:
```dart
router.go('/accounts/shopping-list');
```
to:
```dart
router.go('/home/shopping-list');
```

Update assertions:
```dart
expect(leaf.matchedLocation, '/home/shopping-list');
```

- [ ] **Step 5: Update RT02 — shopping-list/:id uses root navigator**

Change:
```dart
router.go('/accounts/shopping-list/123');
```
to:
```dart
router.go('/home/shopping-list/123');
```

Update assertions:
```dart
expect(leaf.matchedLocation, '/home/shopping-list/123');
```

- [ ] **Step 6: Update RT03 — invalid shopping-list item id redirects**

Change:
```dart
router.go('/accounts/shopping-list/abc');
```
to:
```dart
router.go('/home/shopping-list/abc');
```

Update assertions:
```dart
expect(leaf.matchedLocation, '/home/shopping-list');
```

- [ ] **Step 7: Add new test for /analysis route**

Add a new test:

```dart
testWidgets('/analysis renders AnalysisScreen', (tester) async {
  final db = newTestAppDatabase();
  addTearDown(db.close);
  final container = makeTestContainer(
    db: db,
    extraOverrides: [
      splashGateSnapshotProvider.overrideWithValue(
        SplashGateSnapshot.withInitial(enabled: false, startDate: null),
      ),
    ],
  );
  addTearDown(container.dispose);

  final router = container.read(routerProvider);
  addTearDown(router.dispose);
  router.go('/analysis');

  await tester.pumpWidget(buildTestApp(container: container));
  await tester.pumpAndSettle();

  expect(find.byType(AnalysisScreen), findsOneWidget);
});
```

- [ ] **Step 8: Run the router tests**

```bash
dart format . && flutter test test/unit/app/router_test.dart -v
```

Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add test/unit/app/router_test.dart
git commit -m "test(router): migrate all route assertions from /accounts to new paths"
```

---

### Task 16: Update home_shopping_list_fab_test.dart

**Files:**
- Modify: `test/widget/features/home/home_shopping_list_fab_test.dart`

- [ ] **Step 1: Update the test router helper**

In the `_buildRouter` function, change:
```dart
GoRoute(
  path: '/accounts/shopping-list',
  builder: (_, _) => const Scaffold(body: Text('SHOPPING_LIST_SCREEN')),
),
```
to:
```dart
GoRoute(
  path: '/home/shopping-list',
  builder: (_, _) => const Scaffold(body: Text('SHOPPING_LIST_SCREEN')),
),
```

- [ ] **Step 2: Update HSL04 test assertion**

The test `'HSL04: tapping mini FAB navigates to /accounts/shopping-list'` should now expect the route to be `/home/shopping-list`. Update the test name and any comments accordingly.

- [ ] **Step 3: Run the tests**

```bash
dart format . && flutter test test/widget/features/home/home_shopping_list_fab_test.dart -v
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add test/widget/features/home/home_shopping_list_fab_test.dart
git commit -m "test(home): update shopping-list FAB test to expect /home/shopping-list route"
```

---

### Task 17: Migrate accounts_screen_test.dart to ManageAccountsBody

**Files:**
- Modify: `test/widget/features/accounts/accounts_screen_test.dart`

- [ ] **Step 1: Update imports**

Replace:
```dart
import 'package:ledgerly/features/accounts/accounts_screen.dart';
```
with:
```dart
import 'package:ledgerly/features/accounts/widgets/manage_accounts_body.dart';
```

- [ ] **Step 2: Update the test router helper**

In `_StubRouter.build`, update the routes to reflect new paths:
```dart
GoRoute(
  path: '/settings/manage-accounts/new',
  builder: (_, _) => const Scaffold(body: Text('ADD_ACCOUNT')),
),
GoRoute(
  path: '/settings/manage-accounts/:id',
  builder: (ctx, state) => Scaffold(
    body: Text('EDIT_ACCOUNT_${state.pathParameters['id']}'),
  ),
),
```

- [ ] **Step 3: Update widget construction**

Replace `AccountsScreen()` references with `ManageAccountsBody` wrapped in a Scaffold. The tests should pump `ManageAccountsBody(data: ...)` directly instead of relying on the full screen.

Update the `_wrap` function to render `ManageAccountsBody` inside a Scaffold instead of `AccountsScreen`.

- [ ] **Step 4: Update AS03 (FAB test)**

The FAB test no longer applies to `ManageAccountsBody` (the CTA is in the sheet, not the body). Either:
- Move this test to a new `manage_accounts_sheet_test.dart`, or
- Remove it and add a comment that CTA testing is in the sheet test.

- [ ] **Step 5: Update assertion for AS04 (archive undo)**

The overflow menu now includes "Edit" as the first item. Update the tap target to find "Archive" specifically (it may need `find.text('Archive').last`).

- [ ] **Step 6: Run the tests**

```bash
dart format . && flutter test test/widget/features/accounts/accounts_screen_test.dart -v
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add test/widget/features/accounts/accounts_screen_test.dart
git commit -m "test(accounts): migrate accounts_screen_test to ManageAccountsBody"
```

---

### Task 18: Run full test suite and fix failures

**Files:**
- Various — driven by test failures

- [ ] **Step 1: Run dart format and the full test suite**

```bash
dart format . && flutter test
```

- [ ] **Step 2: Fix any remaining test failures**

Common issues:
- Tests referencing `/accounts/*` routes
- Tests importing deleted files
- Tests asserting old nav labels

- [ ] **Step 3: Run the global /accounts route grep**

```bash
grep -rn "'/accounts" lib/ test/
```

Expected: zero matches for product-route paths. The `accounts` feature-slice directory name is allowed.

- [ ] **Step 4: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "test: fix remaining test failures from accounts-to-analysis refactor"
```

---

## Chunk 6: Documentation And Final Verification

### Task 19: Update PRD.md

**Files:**
- Modify: `PRD.md`

- [ ] **Step 1: Read the full PRD.md**

Read the file to understand all sections that reference `Accounts`.

- [ ] **Step 2: Run the grep to find all Accounts references**

```bash
grep -nE "Accounts(/| |$|\.|,|:)" PRD.md
```

- [ ] **Step 3: Update all references**

Required changes (line numbers approximate):
- `~27`: Shopping list drafts description — change "Accounts screen" to "Home screen"
- `~377-378`: Multi-currency grouping — update if it mentions Accounts screen
- `~547`: Account types — change "Accounts screen" to "Settings > Manage accounts"
- `~670`: Shell route description — change "Home / Accounts / Settings" to "Home / Analysis / Settings"
- `~680`: Route table — replace `/accounts` entries with `/analysis`, `/home/shopping-list`, `/settings/manage-accounts/*`
- `~692`: Route stacking — update to new paths
- `~702`: Bottom navigation — change "Accounts" to "Analysis"
- `~711`: Default account description — update reference
- `~714`: First transaction description — update reference
- `~721`: Accounts Screen description — rewrite as "Manage accounts" in Settings
- `~746`: Accounts empty state — update reference
- `~770`: Shopping list flow — change "Accounts tab" to "Home shopping-cart button"

Ensure the grep after changes returns only:
- Feature-slice name references (e.g., "the accounts feature slice")
- `Manage accounts` (the new Settings entry-point name)
- Intentional historical references

- [ ] **Step 4: Verify the grep**

```bash
grep -nE "Accounts(/| |$|\.|,|:)" PRD.md
```

Manually review each match to confirm it's in the allowed list.

- [ ] **Step 5: Run dart format**

```bash
dart format PRD.md 2>/dev/null || true
```

- [ ] **Step 6: Commit**

```bash
git add PRD.md
git commit -m "docs(prd): update all Accounts references to Analysis/Manage accounts"
```

---

### Task 20: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Run the grep**

```bash
grep -nE "Accounts(/| |$|\.|,|:)" README.md
```

- [ ] **Step 2: Update all references**

Ensure the README explains:
- `Analysis` exists but is intentionally empty in MVP
- Accounts are managed from `Settings > Manage accounts`
- Shopping list is entered from the Home shopping-cart button

- [ ] **Step 3: Verify the grep**

```bash
grep -nE "Accounts(/| |$|\.|,|:)" README.md
```

Remaining matches should be: feature-slice name in project layout, or `Manage accounts`.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs(readme): update structure to reflect Analysis/Manage accounts/shopping list changes"
```

---

### Task 21: Final verification — full suite and release-gate greps

**Files:**
- None (verification only)

- [ ] **Step 1: Run dart format**

```bash
dart format .
```

- [ ] **Step 2: Run flutter analyze**

```bash
flutter analyze
```

Expected: PASS.

- [ ] **Step 3: Run the full test suite**

```bash
flutter test
```

Expected: PASS.

- [ ] **Step 4: Run import lint**

```bash
dart run import_lint
```

Expected: PASS.

- [ ] **Step 5: Run the release-gate greps**

```bash
grep -rn "'/accounts" lib/ test/
grep -nE "Accounts(/| |$|\.|,|:)" PRD.md
grep -nE "Accounts(/| |$|\.|,|:)" README.md
```

Verify all results are in allowed lists.

- [ ] **Step 6: Run codegen to ensure generated files are fresh**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Final commit if any generated files changed**

```bash
git add -A
git commit -m "chore: regenerate code after accounts-to-analysis refactor"
```

---

## Summary

| Chunk | Tasks | Description                                                                                     |
|-------|-------|-------------------------------------------------------------------------------------------------|
| 1     | 1–3   | Localization keys, AdaptiveShell label, AnalysisScreen                                          |
| 2     | 4–7   | AccountTile onEdit, ManageAccountsBody, ManageAccountsSheet, ManageAccountsTile, SettingsScreen |
| 3     | 8     | Router overhaul — replace /accounts branch                                                      |
| 4     | 9–14  | Route migration — fix all callers, delete old files                                             |
| 5     | 15–18 | Test migration — update all test files                                                          |
| 6     | 19–21 | Documentation updates and final verification                                                    |
