# Analysis Tab And Settings-Owned Account Management — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the Accounts tab to Analysis, move account management into Settings > Manage accounts, make shopping list a Home-owned flow, keep the Home shopping-cart FAB as the only draft-rediscovery entry point, and update documentation.

**Architecture:** Information-architecture refactor only — no Drift schema or repository changes. The middle shell destination changes from `/accounts` (AccountsScreen) to `/analysis` (AnalysisScreen placeholder). Account management must relocate into a Settings-owned adaptive sheet/dialog (`Manage accounts`) and is no longer a top-level destination. Shopping list moves from the Accounts branch to the Home branch, and the Home shopping-cart FAB becomes the only remaining rediscovery affordance for saved drafts. Caller, test, and documentation migrations land across later tasks; the old `/accounts*` routes can be removed in the router task even if temporary breakage exists until those follow-up migrations are complete. No backward-compatible redirects from `/accounts*` are required.

**Tech Stack:** Flutter, Riverpod, go_router, Drift, flutter_slidable, flutter_secure_storage (unchanged), ARB localization

---

## File Structure

### New Files
| File                                                            | Responsibility                                                                                                                     |
|-----------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| `lib/features/analysis/analysis_screen.dart`                    | Phase 2 placeholder screen for the `/analysis` route                                                                               |
| `lib/features/accounts/widgets/manage_accounts_body.dart`       | Relocated data-state body from `accounts_screen.dart` — scrollable account-management content for the Manage accounts sheet/dialog |
| `lib/features/settings/widgets/manage_accounts_sheet.dart`      | Settings-owned adaptive sheet/dialog that hosts `ManageAccountsBody` and the pinned create-account CTA                             |
| `lib/features/settings/widgets/manage_accounts_tile.dart`       | Settings list row — renamed user-facing concept from "Default account" to "Manage accounts" with count-aware subtitle              |
| `test/widget/features/analysis/analysis_screen_test.dart`       | Widget coverage for the Analysis placeholder screen                                                                                |
| `test/widget/features/accounts/manage_accounts_body_test.dart`  | Widget coverage for `ManageAccountsBody` rendering and account-row interactions                                                    |
| `test/widget/features/accounts/manage_accounts_sheet_test.dart` | Widget coverage for the Settings-owned Manage accounts sheet/dialog, including loading/error/data states and create CTA routing    |

### Modified Files
| File                                                          | Changes                                                                                                                                                                                |
|---------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `lib/app/router.dart`                                         | Replace `/accounts` branch with `/analysis`; add `/home/shopping-list*` routes; add `/settings/manage-accounts/new` + `/settings/manage-accounts/:id`; remove old `/accounts/*` routes |
| `lib/app/widgets/adaptive_shell.dart`                         | Change middle tab label from `navAccounts` to `navAnalysis`; change icon from `account_balance_wallet` to `analytics_outlined`                                                         |
| `lib/features/home/home_screen.dart`                          | Change shopping-cart FAB from `context.go('/accounts/shopping-list')` to `context.push('/home/shopping-list')`                                                                         |
| `lib/features/shopping_list/shopping_list_screen.dart`        | Change row-tap from `/accounts/shopping-list/$id` to `/home/shopping-list/$id`                                                                                                         |
| `lib/features/transactions/transaction_form_screen.dart`      | Change recovery flow from `/accounts/new` to `/settings/manage-accounts/new`                                                                                                           |
| `lib/features/transactions/widgets/account_picker_sheet.dart` | Change create-account from `/accounts/new` to `/settings/manage-accounts/new`                                                                                                          |
| `lib/features/accounts/account_form_screen.dart`              | Change the no-stack fallback target from `/accounts` to `/settings` while preserving the existing `context.canPop() ? pop() : go(...)` caller-flow behavior                            |
| `lib/features/settings/settings_screen.dart`                  | Replace `DefaultAccountTile` import/usage with `ManageAccountsTile`                                                                                                                    |
| `l10n/app_en.arb`                                             | Add new keys; change `navAccounts` → `navAnalysis`                                                                                                                                     |
| `l10n/app_zh.arb`                                             | Mirror new keys                                                                                                                                                                        |
| `l10n/app_zh_CN.arb`                                          | Mirror new keys                                                                                                                                                                        |
| `l10n/app_zh_TW.arb`                                          | Mirror new keys                                                                                                                                                                        |
| `AGENTS.md`                                                   | Update live route and screen references so agent-facing repo guidance matches the refactor                                                                                             |
| `PRD.md`                                                      | Update all references from Accounts to Analysis/Manage accounts                                                                                                                        |
| `README.md`                                                   | Update user-facing structure description                                                                                                                                               |

### Deleted Files
| File                                                                         | Reason                                                                                             |
|------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| `lib/features/accounts/accounts_screen.dart`                                 | Replaced by `manage_accounts_body.dart` + `manage_accounts_sheet.dart`                             |
| `lib/features/settings/widgets/default_account_tile.dart`                    | Replaced by new `ManageAccountsTile` implementation                                                |
| `lib/features/settings/widgets/default_account_picker_sheet.dart`            | Replaced by new `ManageAccountsSheet` implementation                                               |
| `lib/features/shopping_list/widgets/shopping_list_card.dart`                 | Intentional UX simplification: Home shopping-cart FAB is now the only draft rediscovery affordance |
| `test/widget/features/accounts/accounts_screen_test.dart`                    | Replaced by focused `manage_accounts_body_test.dart` + `manage_accounts_sheet_test.dart`           |
| `test/widget/features/shopping_list/shopping_list_card_test.dart`            | Tests deleted widget                                                                               |
| `test/widget/features/shopping_list/shopping_list_card_add_button_test.dart` | Tests deleted widget                                                                               |

### Test Files
| File                                                                                | Changes                                                                                                   |
|-------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| `test/unit/app/router_test.dart`                                                    | Migrate all `/accounts*` assertions to `/analysis`, `/settings/manage-accounts/*`, `/home/shopping-list*` |
| `test/widget/features/home/home_shopping_list_fab_test.dart`                        | Change expected route from `/accounts/shopping-list` to `/home/shopping-list`                             |
| `test/unit/l10n/arb_audit_test.dart`                                                | Rename expected shell key from `navAccounts` to `navAnalysis`                                             |
| `test/widget/smoke/app_localizations_groups_test.dart`                              | Assert `navAnalysis` instead of `navAccounts`                                                             |
| `test/widget/features/settings/settings_screen_test.dart`                           | Replace Default-account tile expectations with Manage-accounts tile expectations                          |
| `test/widget/features/shopping_list/shopping_list_screen_test.dart`                 | Change row-tap route from `/accounts/shopping-list/:id` to `/home/shopping-list/:id`                      |
| `test/widget/features/transactions/transaction_form_shopping_list_button_test.dart` | Change create-account stub route to `/settings/manage-accounts/new`                                       |
| `test/widget/features/accounts/account_form_screen_test.dart`                       | Change helper routes and copy from `/accounts*` to `/settings/manage-accounts*` / `/settings`             |
| `test/integration/shopping_list_path_test.dart`                                     | Replace Accounts-tab draft rediscovery with Home shopping-cart FAB flow                                   |
| `test/integration/archive_flow_test.dart`                                           | Replace Accounts-screen archived-section assertions with Settings > Manage accounts assertions            |
| New: `test/widget/features/analysis/analysis_screen_test.dart`                      | Test AnalysisScreen renders placeholder                                                                   |
| New: `test/widget/features/accounts/manage_accounts_body_test.dart`                 | Test ManageAccountsBody rendering, archive undo, and row routing                                          |
| New: `test/widget/features/accounts/manage_accounts_sheet_test.dart`                | Test ManageAccountsSheet open/close, loading/error/data states, and create-account CTA                    |

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

- [x] **Step 1: Read current l10n files to understand structure**

Read `l10n/app_en.arb`, `l10n/app_zh.arb`, `l10n/app_zh_CN.arb`, `l10n/app_zh_TW.arb` to understand existing keys and structure.

- [x] **Step 2: Rename `navAccounts` to `navAnalysis` in app_en.arb**

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

- [x] **Step 3: Add new l10n keys to app_en.arb**

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

- [x] **Step 4: Mirror changes to app_zh.arb, app_zh_CN.arb, app_zh_TW.arb**

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

- [x] **Step 5: Run Flutter l10n codegen**

```bash
flutter gen-l10n
```

Verify `lib/l10n/app_localizations.dart` now contains `navAnalysis`, all `manageAccounts*` keys, and `analysisPlaceholder*` keys.

- [x] **Step 6: Fix any broken references to `navAccounts`**

```bash
grep -rn "navAccounts" lib/
```

Replace any remaining references to `navAccounts` with `navAnalysis`. Expected: only `adaptive_shell.dart` and generated files reference it.

- [x] **Step 7: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS (may have existing warnings but no new errors).

- [x] **Step 8: Commit**

```bash
git add l10n/ lib/l10n/
git commit -m "feat(l10n): add manage-accounts and analysis keys, rename navAccounts to navAnalysis"
```

---

### Task 2: Update AdaptiveShell label and icon

**Files:**
- Modify: `lib/app/widgets/adaptive_shell.dart:44,61`

- [x] **Step 1: Change the middle tab label and icon**

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

- [x] **Step 2: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [x] **Step 3: Commit**

```bash
git add lib/app/widgets/adaptive_shell.dart
git commit -m "feat(ui): rename middle tab from Accounts to Analysis with analytics icon"
```

---

### Task 3: Create AnalysisScreen

**Files:**
- Create: `lib/features/analysis/analysis_screen.dart`

- [x] **Step 1: Create the AnalysisScreen**

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

- [x] **Step 2: Write a widget test for AnalysisScreen**

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

    expect(find.text('Analysis'), findsOneWidget); // AppBar title only
  });

  testWidgets('AN03: AnalysisScreen has no FAB', (tester) async {
    await tester.pumpWidget(_wrap(child: const AnalysisScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
```

- [x] **Step 3: Run the test**

```bash
dart format . && flutter test test/widget/features/analysis/analysis_screen_test.dart -v
```

Expected: PASS (all 3 tests).

- [x] **Step 4: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add lib/features/analysis/analysis_screen.dart test/widget/features/analysis/analysis_screen_test.dart
git commit -m "feat(analysis): add AnalysisScreen with Phase 2 placeholder"
```

---

## Chunk 2: AccountTile And Manage Accounts Body

### Task 4: Keep AccountTile behavior unchanged

**Files:**
- Read only: `lib/features/accounts/widgets/account_tile.dart`

- [x] **Step 1: Read the current AccountTile behavior**

Read `lib/features/accounts/widgets/account_tile.dart` and confirm the current affordances:
- row tap opens account edit
- active rows keep the existing overflow and swipe actions
- archived rows suppress swipe actions and trailing overflow

- [x] **Step 2: Do not add new Edit-only overflow behavior in this refactor**

This plan is an information-architecture move, not an account-row affordance redesign. Reuse the existing row-tap edit path from the relocated Manage accounts surface.

- [x] **Step 3: Skip AccountTile edits and tests unless a later implementation blocker proves they are required**

Expected outcome for this task: no code changes.

### Task 5: Create ManageAccountsBody (relocated from AccountsScreen)

**Files:**
- Create: `lib/features/accounts/widgets/manage_accounts_body.dart`
- Read: `lib/features/accounts/accounts_screen.dart` (will be deleted in Task 19)

- [x] **Step 1: Read the full accounts_screen.dart to understand classes to relocate**

Read `lib/features/accounts/accounts_screen.dart` (368 lines). The classes to relocate are:
- `_AccountsBody` (~lines 68–155) — the main body with CustomScrollView
- `_AccountTileWithLookups` (~lines 157–243) — wraps AccountTile with provider lookups
- `_AccountListCard` (~lines 245–290) — the card container

Do **not** relocate `_ErrorSurface`. Error/loading handling will live in `ManageAccountsSheet`; `ManageAccountsBody` is a data-state-only widget.

- [x] **Step 2: Create manage_accounts_body.dart**

Create `lib/features/accounts/widgets/manage_accounts_body.dart`:

```dart
// Manage accounts body content.
//
// Relocated from the deleted `accounts_screen.dart`. Renders the active and
// archived account lists inside the Settings-owned Manage accounts surface.
// This widget assumes the caller already resolved the data state.

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

    const cardPadding = EdgeInsets.symmetric(
      horizontal: homePageCardHorizontalPadding - 16,
    );

    final allActiveIds = data.active
        .map((r) => r.account.id)
        .toList(growable: false);

    return SlidableAutoCloseBehavior(
      child: CustomScrollView(
        slivers: [
          if (data.active.isNotEmpty)
            SliverPadding(
              padding: cardPadding.copyWith(top: 16),
              sliver: SliverToBoxAdapter(
                child: _AccountListCard(
                  accounts: data.active,
                  defaultAccountId: data.defaultAccountId,
                  locale: locale,
                  allActiveIds: allActiveIds,
                ),
              ),
            ),
          if (data.active.isEmpty && data.archived.isEmpty)
            SliverPadding(
              padding: cardPadding.copyWith(top: 16),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.manageAccountsBodyEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (data.archived.isNotEmpty)
            SliverPadding(
              padding: cardPadding,
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 8),
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
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
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
      onSetDefault: () => _onSetDefault(
        context,
        ref,
        view.account.id,
        view.account.name,
      ),
      onArchive: () => _onArchive(context, ref, view.account.id),
      onDelete: () => _onDelete(context, ref, view.account.id),
      onArchiveBlocked: () => _onArchiveBlocked(context),
    );
  }

  Future<void> _onSetDefault(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountsControllerProvider.notifier).setDefault(id);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.manageAccountsSetDefaultSuccess(name))),
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

- [x] **Step 3: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [x] **Step 4: Commit**

```bash
git add lib/features/accounts/widgets/manage_accounts_body.dart
git commit -m "feat(accounts): create ManageAccountsBody relocated from AccountsScreen"
```

---

### Task 6: Create ManageAccountsSheet and ManageAccountsTile

**Files:**
- Create: `lib/features/settings/widgets/manage_accounts_sheet.dart`
- Create: `lib/features/settings/widgets/manage_accounts_tile.dart`
- Delete later: `lib/features/settings/widgets/default_account_picker_sheet.dart`
- Delete later: `lib/features/settings/widgets/default_account_tile.dart`

- [x] **Step 1: Create manage_accounts_sheet.dart**

Create `lib/features/settings/widgets/manage_accounts_sheet.dart`:

```dart
// Manage accounts sheet — Settings-owned entry point.
//
// Adaptive: bottom sheet (<600dp) or dialog (>=600dp). Hosts
// ManageAccountsBody. The sheet/dialog remains mounted behind
// create/edit routes; AccountFormScreen keeps its existing
// `context.canPop() ? context.pop() : context.go('/settings')`
// behavior so caller flows return to the sheet when launched from it.

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

- [x] **Step 2: Create manage_accounts_tile.dart**

Create `lib/features/settings/widgets/manage_accounts_tile.dart`:

```dart
// Manage accounts tile — Settings list row.
//
// Replacement for DefaultAccountTile. Shows "Manage accounts" with a
// count-aware subtitle that reads account rows from
// `accountsControllerProvider` and only uses settings state for the
// current `defaultAccountId`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../settings_controller.dart';
import '../settings_providers.dart';
import '../../accounts/accounts_controller.dart';
import '../../accounts/accounts_state.dart';
import '../settings_state.dart';
import 'manage_accounts_sheet.dart';

class ManageAccountsTile extends ConsumerWidget {
  const ManageAccountsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountsControllerProvider);
    final defaultAccountId = ref.watch(settingsControllerProvider).maybeWhen(
      data: (SettingsState state) => switch (state) {
        SettingsData(:final defaultAccountId) => defaultAccountId,
        _ => null,
      },
      orElse: () => null,
    );

    final subtitle = accountsAsync.maybeWhen(
      data: (state) {
        final data = state;
        if (data is! AccountsData) return '';
        if (data.active.isEmpty) return l10n.manageAccountsTileSubtitleAddCta;
        if (data.active.length == 1) return data.active.first.account.name;
        // N≥2: find default name + "+N more"
        final defaultMatches = data.active.where(
          (r) => r.account.id == defaultAccountId,
        );
        final defaultName = defaultMatches.isNotEmpty
            ? defaultMatches.first.account.name
            : data.active.first.account.name;
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

- [x] **Step 3: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [x] **Step 4: Commit**

```bash
git add lib/features/settings/widgets/manage_accounts_sheet.dart lib/features/settings/widgets/manage_accounts_tile.dart
git commit -m "feat(settings): create ManageAccountsSheet and ManageAccountsTile"
```

---

### Task 7: Update SettingsScreen to use ManageAccountsTile

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`
- Delete later: `lib/features/settings/widgets/default_account_tile.dart`
- Delete later: `lib/features/settings/widgets/default_account_picker_sheet.dart`

- [x] **Step 1: Replace DefaultAccountTile import and usage**

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
const ManageAccountsTile(),
```

- [x] **Step 2: Leave file deletion to Task 19**

Do not delete `default_account_tile.dart` or `default_account_picker_sheet.dart` in this task. Cleanup happens in Task 19 after all callers and tests are migrated.

- [x] **Step 3: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [x] **Step 4: Commit**

```bash
git add lib/features/settings/settings_screen.dart lib/features/settings/widgets/manage_accounts_tile.dart lib/features/settings/widgets/manage_accounts_sheet.dart
git commit -m "feat(settings): move account management under Settings"
```

---

## Chunk 3: Router Overhaul

### Task 8: Rewrite router.dart — replace /accounts branch with /analysis, add new routes

**Files:**
- Modify: `lib/app/router.dart`

- [x] **Step 1: Read the full router.dart to understand current structure**

Read `lib/app/router.dart` (255 lines). Key structure:
- 3 StatefulShellBranch: `/home`, `/accounts`, `/settings`
- `/accounts` branch has: `AccountsScreen`, `/accounts/new`, `/accounts/shopping-list`, `/accounts/shopping-list/:itemId`, `/accounts/:id`

- [x] **Step 2: Update imports**

Replace:
```dart
import '../features/accounts/accounts_screen.dart';
```
with:
```dart
import '../features/analysis/analysis_screen.dart';
```

Keep the `AccountFormScreen` import — it's still used.

- [x] **Step 3: Replace the middle branch**

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

- [x] **Step 4: Add shopping-list routes under the Home branch**

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

This preserves the current missing-draft behavior because `TransactionFormScreen`
already auto-pops `ShoppingListEditResultMissingDraft` when the id parses but
the draft row no longer exists, and `ShoppingListScreen` already maps that
result to the localized `shoppingListDraftNotFoundSnackbar`.

- [x] **Step 5: Add manage-accounts routes under the Settings branch**

Inside the `/settings` route's `routes` list, add:

Note: `/settings/manage-accounts` itself is intentionally **not** a base route.
The main Manage accounts surface opens imperatively from `ManageAccountsTile`
via `showManageAccountsSheet(context)`. Only the create/edit forms are
route-addressable under `/settings/manage-accounts/new` and
`/settings/manage-accounts/:id`.

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

- [x] **Step 6: Remove old /accounts routes**

Remove the entire old `/accounts` branch and its child routes. Do not add legacy redirects from `/accounts*` to the new locations. The `ShoppingListScreen` import should now point to the Home branch version.

- [x] **Step 7: Add ShoppingListScreen import if not already present**

Ensure this import exists:
```dart
import '../features/shopping_list/shopping_list_screen.dart';
```

- [x] **Step 8: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: analyze may fail here because other files can still reference old routes. Full analyzer pass is verified after the remaining route migrations land in Chunk 4.

- [x] **Step 9: Run codegen**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [x] **Step 10: Commit**

```bash
git add lib/app/router.dart lib/app/router.g.dart
git commit -m "feat(router): replace /accounts branch with /analysis, add /home/shopping-list and /settings/manage-accounts routes"
```

---

## Chunk 4: Route Migration — Fix All Callers

### Task 9: Update HomeScreen shopping-cart FAB

**Files:**
- Modify: `lib/features/home/home_screen.dart:162`

- [x] **Step 1: Change the shopping-cart FAB navigation**

In `lib/features/home/home_screen.dart`, line 162:

Replace:
```dart
onPressed: () => context.go('/accounts/shopping-list'),
```
with:
```dart
onPressed: () => context.push('/home/shopping-list'),
```

- [x] **Step 2: Run dart format**

```bash
dart format lib/features/home/home_screen.dart
```

- [x] **Step 3: Commit**

```bash
git add lib/features/home/home_screen.dart
git commit -m "feat(home): change shopping-cart FAB to push /home/shopping-list"
```

---

### Task 10: Update ShoppingListScreen row-tap route

**Files:**
- Modify: `lib/features/shopping_list/shopping_list_screen.dart:112`

- [x] **Step 1: Change the row-tap navigation**

In `lib/features/shopping_list/shopping_list_screen.dart`, line 112:

Replace:
```dart
'/accounts/shopping-list/$id',
```
with:
```dart
'/home/shopping-list/$id',
```

- [x] **Step 2: Run dart format**

```bash
dart format lib/features/shopping_list/shopping_list_screen.dart
```

- [x] **Step 3: Commit**

```bash
git add lib/features/shopping_list/shopping_list_screen.dart
git commit -m "feat(shopping-list): change row-tap route to /home/shopping-list/:id"
```

---

### Task 11: Update TransactionFormScreen recovery flow

**Files:**
- Modify: `lib/features/transactions/transaction_form_screen.dart:694`

- [x] **Step 1: Find the /accounts/new reference**

In `lib/features/transactions/transaction_form_screen.dart`, find the line that pushes `/accounts/new` in the recovery flow (around line 694):

```dart
context.push('/accounts/new').then(...)
```

Replace with:
```dart
context.push('/settings/manage-accounts/new').then(...)
```

- [x] **Step 2: Run dart format**

```bash
dart format lib/features/transactions/transaction_form_screen.dart
```

- [x] **Step 3: Commit**

```bash
git add lib/features/transactions/transaction_form_screen.dart
git commit -m "feat(transactions): change create-account recovery route to /settings/manage-accounts/new"
```

---

### Task 12: Update AccountPickerSheet create-account route

**Files:**
- Modify: `lib/features/transactions/widgets/account_picker_sheet.dart:50`

- [x] **Step 1: Change the create-account navigation**

In `lib/features/transactions/widgets/account_picker_sheet.dart`, line 50:

Replace:
```dart
final savedId = await context.push<int>('/accounts/new');
```
with:
```dart
final savedId = await context.push<int>('/settings/manage-accounts/new');
```

- [x] **Step 2: Run dart format**

```bash
dart format lib/features/transactions/widgets/account_picker_sheet.dart
```

- [x] **Step 3: Commit**

```bash
git add lib/features/transactions/widgets/account_picker_sheet.dart
git commit -m "feat(transactions): change create-account route to /settings/manage-accounts/new"
```

---

### Task 13: Update AccountFormScreen fallback routes

**Files:**
- Modify: `lib/features/accounts/account_form_screen.dart:150,306`

- [x] **Step 1: Change the _NotFoundSurface fallback**

Preserve the existing caller-flow behavior: keep the surrounding
`context.canPop() ? context.pop() : context.go(...)` contract in both places.
Only change the no-stack fallback target from `/accounts` to `/settings`.

In `lib/features/accounts/account_form_screen.dart`, line 150:

Replace:
```dart
context.go('/accounts');
```
with:
```dart
context.go('/settings');
```

- [x] **Step 2: Change the Cancel button fallback**

In the same file, line 306:

Replace:
```dart
context.go('/accounts');
```
with:
```dart
context.go('/settings');
```

- [x] **Step 3: Verify no remaining /accounts references**

```bash
grep -n "/accounts" lib/features/accounts/account_form_screen.dart
```

Expected: zero matches outside import statements and generated code.

- [x] **Step 4: Run dart format**

```bash
dart format lib/features/accounts/account_form_screen.dart
```

- [x] **Step 5: Commit**

```bash
git add lib/features/accounts/account_form_screen.dart
git commit -m "feat(accounts): change form fallback routes from /accounts to /settings"
```

---

### Task 14: Prepare for later deletion of old AccountsScreen and ShoppingListCard files

**Files:**
- Delete: `lib/features/accounts/accounts_screen.dart`
- Delete: `lib/features/shopping_list/widgets/shopping_list_card.dart`
- Delete: `test/widget/features/shopping_list/shopping_list_card_test.dart`
- Delete: `test/widget/features/shopping_list/shopping_list_card_add_button_test.dart`

- [x] **Step 1: Verify no remaining imports of deleted files**

```bash
grep -rn "accounts_screen.dart\|shopping_list_card.dart" lib/ test/
```

Expected: this will still show matches at this point. Use it as a baseline only.

- [x] **Step 2: Do not delete the files yet**

This is an intentional behavior change, not a temporary gap: do not re-home `ShoppingListCard` onto Home in this refactor. Saved drafts are rediscovered only through the Home shopping-cart FAB. Actual file deletion moves to a later cleanup task after the explicit test migrations are complete.

- [x] **Step 3: Continue to the explicit test migrations in Chunk 5**

Do not remove `accounts_screen.dart` or `shopping_list_card.dart` until Tasks 17-18 are complete.

---

## Chunk 5: Test Migration

### Task 15: Update router_test.dart

**Files:**
- Modify: `test/unit/app/router_test.dart`

- [x] **Step 1: Update imports**

Replace:
```dart
import 'package:ledgerly/features/accounts/accounts_screen.dart';
```
with:
```dart
import 'package:ledgerly/features/analysis/analysis_screen.dart';
```

Keep the `AccountFormScreen` and `ShoppingListScreen` imports.

- [x] **Step 2: Update /accounts/new test to /settings/manage-accounts/new**

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

- [x] **Step 3: Update /accounts/:id invalid id test**

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

- [x] **Step 4: Update RT01 — shopping-list renders ShoppingListScreen**

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

- [x] **Step 5: Update RT02 — shopping-list/:id uses root navigator**

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

- [x] **Step 6: Update RT03 — invalid shopping-list item id redirects**

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

- [x] **Step 7: Add new test for /analysis route**

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

- [x] **Step 8: Run the router tests**

```bash
dart format . && flutter test test/unit/app/router_test.dart -v
```

Expected: PASS.

- [x] **Step 9: Commit**

```bash
git add test/unit/app/router_test.dart
git commit -m "test(router): migrate all route assertions from /accounts to new paths"
```

---

### Task 16: Update home_shopping_list_fab_test.dart

**Files:**
- Modify: `test/widget/features/home/home_shopping_list_fab_test.dart`

- [x] **Step 1: Update the test router helper**

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

- [x] **Step 2: Update HSL04 test assertion**

The test `'HSL04: tapping mini FAB navigates to /accounts/shopping-list'` should now expect the route to be `/home/shopping-list`. Update the test name and any comments accordingly.

- [x] **Step 3: Run the tests**

```bash
dart format . && flutter test test/widget/features/home/home_shopping_list_fab_test.dart -v
```

Expected: PASS.

- [x] **Step 4: Commit**

```bash
git add test/widget/features/home/home_shopping_list_fab_test.dart
git commit -m "test(home): update shopping-list FAB test to expect /home/shopping-list route"
```

---

### Task 17: Split AccountsScreen test coverage into ManageAccountsBody and ManageAccountsSheet tests

**Files:**
- Delete: `test/widget/features/accounts/accounts_screen_test.dart`
- Create: `test/widget/features/accounts/manage_accounts_body_test.dart`
- Create: `test/widget/features/accounts/manage_accounts_sheet_test.dart`

- [x] **Step 1: Split body coverage into manage_accounts_body_test.dart**

Create `test/widget/features/accounts/manage_accounts_body_test.dart` by migrating the existing body-centric assertions from `accounts_screen_test.dart`:
- active rows render with the default badge
- archived section renders
- empty-state body text renders when no active or archived rows exist
- archive action shows undo snackbar
- native-currency balances still render correctly
- 2x text scale survives

- [x] **Step 2: Split surface/CTA coverage into manage_accounts_sheet_test.dart**

Create `test/widget/features/accounts/manage_accounts_sheet_test.dart` for the Settings-owned surface and move the old FAB-equivalent coverage here:
- opening the sheet from `ManageAccountsTile`
- loading / error / data state rendering
- create-account CTA routes to `/settings/manage-accounts/new`
- row-tap/edit routes to `/settings/manage-accounts/:id`
- close button dismisses the sheet/dialog

- [x] **Step 3: Delete the old accounts_screen_test.dart**

Delete `test/widget/features/accounts/accounts_screen_test.dart` after the new body/sheet tests are green.

- [x] **Step 4: Run the split account-management tests**

```bash
dart format . && flutter test test/widget/features/accounts/manage_accounts_body_test.dart -v && flutter test test/widget/features/accounts/manage_accounts_sheet_test.dart -v
```

Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add test/widget/features/accounts/manage_accounts_body_test.dart test/widget/features/accounts/manage_accounts_sheet_test.dart test/widget/features/accounts/accounts_screen_test.dart
git commit -m "test(accounts): split AccountsScreen coverage into manage accounts body and sheet tests"
```

---

### Task 18: Update route- and l10n-dependent tests not covered above

**Files:**
- Modify: `test/widget/features/settings/settings_screen_test.dart`
- Modify: `test/widget/features/shopping_list/shopping_list_screen_test.dart`
- Modify: `test/widget/features/transactions/transaction_form_shopping_list_button_test.dart`
- Modify: `test/widget/features/accounts/account_form_screen_test.dart`
- Modify: `test/integration/shopping_list_path_test.dart`
- Modify: `test/integration/archive_flow_test.dart`
- Modify: `test/unit/l10n/arb_audit_test.dart`
- Modify: `test/widget/smoke/app_localizations_groups_test.dart`

- [x] **Step 1: Update SettingsScreen tests to the Manage accounts entrypoint**

In `test/widget/features/settings/settings_screen_test.dart`:
- change the stub route from `/accounts/new` to `/settings/manage-accounts/new`
- rename the old default-account tile assertions to Manage-accounts tile assertions
- update keys/text to `settingsManageAccountsTile` and the new subtitle behavior

- [x] **Step 2: Update ShoppingListScreen tests to `/home/shopping-list/:id`**

In `test/widget/features/shopping_list/shopping_list_screen_test.dart`:
- change the row-tap stub route from `/accounts/shopping-list/:id` to `/home/shopping-list/:id`
- update the SLS04 test name/comments accordingly

- [x] **Step 3: Update transaction-form shopping-list tests to the new create-account route**

In `test/widget/features/transactions/transaction_form_shopping_list_button_test.dart`, change the create-account stub route from `/accounts/new` to `/settings/manage-accounts/new`.

- [x] **Step 4: Update account-form tests to the new helper routes and fallback copy**

In `test/widget/features/accounts/account_form_screen_test.dart`:
- change helper routes from `/accounts/new` and `/accounts/:id` to `/settings/manage-accounts/new` and `/settings/manage-accounts/:id`
- change the root list/fallback route from `/accounts` to `/settings`
- rename the not-found expectation from `pops to /accounts` to `goes to /settings when no route is left on the stack`

- [x] **Step 5: Update the shopping-list integration flow to use Home-owned rediscovery**

In `test/integration/shopping_list_path_test.dart`:
- remove `AccountsScreen` imports/assertions
- replace taps on the `Accounts` tab with the Home shopping-cart FAB
- change direct pushes from `/accounts/shopping-list/$draftId` to `/home/shopping-list/$draftId`

- [x] **Step 6: Update archived-account integration assertions to Settings > Manage accounts**

In `test/integration/archive_flow_test.dart`:
- remove the `AccountsScreen` import
- replace the `Accounts` tab navigation/assertion with the Settings tab, then open `Manage accounts`
- assert the archived account appears in the Manage accounts archived section

- [x] **Step 7: Update l10n regression tests for `navAnalysis`**

In:
- `test/unit/l10n/arb_audit_test.dart`
- `test/widget/smoke/app_localizations_groups_test.dart`

Replace `navAccounts` expectations with `navAnalysis`.

- [x] **Step 8: Run the targeted migration tests**

```bash
dart format . && flutter test test/widget/features/settings/settings_screen_test.dart -v && flutter test test/widget/features/shopping_list/shopping_list_screen_test.dart -v && flutter test test/widget/features/transactions/transaction_form_shopping_list_button_test.dart -v && flutter test test/widget/features/accounts/account_form_screen_test.dart -v && flutter test test/integration/shopping_list_path_test.dart -v && flutter test test/integration/archive_flow_test.dart -v && flutter test test/unit/l10n/arb_audit_test.dart -v && flutter test test/widget/smoke/app_localizations_groups_test.dart -v
```

Expected: PASS.

- [x] **Step 9: Commit**

```bash
git add test/widget/features/settings/settings_screen_test.dart test/widget/features/shopping_list/shopping_list_screen_test.dart test/widget/features/transactions/transaction_form_shopping_list_button_test.dart test/widget/features/accounts/account_form_screen_test.dart test/integration/shopping_list_path_test.dart test/integration/archive_flow_test.dart test/unit/l10n/arb_audit_test.dart test/widget/smoke/app_localizations_groups_test.dart
git commit -m "test: migrate remaining route and localization tests for analysis and manage accounts"
```

---

### Task 19: Delete old AccountsScreen, ShoppingListCard, and superseded tests

**Files:**
- Delete: `lib/features/accounts/accounts_screen.dart`
- Delete: `lib/features/settings/widgets/default_account_tile.dart`
- Delete: `lib/features/settings/widgets/default_account_picker_sheet.dart`
- Delete: `lib/features/shopping_list/widgets/shopping_list_card.dart`
- Delete: `test/widget/features/shopping_list/shopping_list_card_test.dart`
- Delete: `test/widget/features/shopping_list/shopping_list_card_add_button_test.dart`

- [x] **Step 1: Verify no remaining imports of deleted files**

```bash
grep -rn "accounts_screen.dart\|shopping_list_card.dart\|default_account_tile.dart\|default_account_picker_sheet.dart" lib/ test/
```

Expected: zero matches.

- [x] **Step 2: Delete the files**

```bash
rm lib/features/accounts/accounts_screen.dart
rm lib/features/settings/widgets/default_account_tile.dart
rm lib/features/settings/widgets/default_account_picker_sheet.dart
rm lib/features/shopping_list/widgets/shopping_list_card.dart
rm test/widget/features/shopping_list/shopping_list_card_test.dart
rm test/widget/features/shopping_list/shopping_list_card_add_button_test.dart
```

- [x] **Step 3: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS. Fix any remaining import errors.

- [x] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: delete obsolete accounts and shopping-list surfaces"
```

---

### Task 20: Run full test suite and fix failures

**Files:**
- Various — driven by test failures

- [x] **Step 1: Run dart format and the full test suite**

```bash
dart format . && flutter test
```

- [x] **Step 2: Fix any remaining test failures**

Common issues:
- Tests referencing `/accounts/*` routes
- Tests importing deleted files
- Tests asserting old nav labels

- [x] **Step 3: Run the global /accounts route grep**

```bash
grep -rn "'/accounts" lib/ test/
```

Expected: zero matches for product-route paths. The `accounts` feature-slice directory name is allowed.

- [x] **Step 4: Run dart format and analyze**

```bash
dart format . && flutter analyze
```

Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add -A
git commit -m "test: fix remaining test failures from accounts-to-analysis refactor"
```

---

## Chunk 6: Documentation And Final Verification

### Task 21: Update PRD.md

**Files:**
- Modify: `PRD.md`

- [x] **Step 1: Read the full PRD.md**

Read the file to understand all sections that reference `Accounts`.

- [x] **Step 2: Run the greps to find both prose and route references**

```bash
grep -nE "Accounts(/| |$|\.|,|:)" PRD.md
grep -n "/accounts" PRD.md
```

- [x] **Step 3: Update all references**

Required changes (line numbers approximate):
- `~27`: Shopping list drafts description — change "Accounts screen" to "Home shopping-cart button" (the only draft rediscovery affordance)
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
- `~770`: Shopping list flow — change "Accounts tab" to "Home shopping-cart button" and note that this is the only draft rediscovery affordance in MVP

Ensure the grep after changes returns only:
- Feature-slice name references (e.g., "the accounts feature slice")
- Intentional historical references

- [x] **Step 4: Verify the grep**

```bash
grep -nE "Accounts(/| |$|\.|,|:)" PRD.md
grep -n "/accounts" PRD.md
```

Manually review each match to confirm it's in the allowed list.

- [x] **Step 5: Run dart format**

```bash
dart format PRD.md 2>/dev/null || true
```

- [x] **Step 6: Commit**

```bash
git add PRD.md
git commit -m "docs(prd): update all Accounts references to Analysis/Manage accounts"
```

---

### Task 22: Update README.md

**Files:**
- Modify: `README.md`

- [x] **Step 1: Run the greps**

```bash
grep -nE "Accounts(/| |$|\.|,|:)" README.md
grep -n "/accounts" README.md
```

- [x] **Step 2: Update all references**

Ensure the README explains:
- `Analysis` exists but is intentionally empty in MVP
- Accounts are managed from `Settings > Manage accounts`
- Shopping list is entered and rediscovered only from the Home shopping-cart button

- [x] **Step 3: Verify the grep**

```bash
grep -nE "Accounts(/| |$|\.|,|:)" README.md
grep -n "/accounts" README.md
```

Remaining matches should be: feature-slice name in project layout, or other intentional historical references that still contain capitalized `Accounts`.

- [x] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs(readme): update structure to reflect Analysis/Manage accounts/shopping list changes"
```

---

### Task 23: Update AGENTS.md

**Files:**
- Modify: `AGENTS.md`

- [x] **Step 1: Update the live route summary**

Update the current-runtime summary so it reflects the new router shape:
- `/analysis` instead of `/accounts`
- `/home/shopping-list` under Home
- `/settings/manage-accounts/new`
- `/settings/manage-accounts/:id`

- [x] **Step 2: Update any stale top-level Accounts-screen references**

Keep feature-slice directory references like `lib/features/accounts/`, but remove any guidance that still describes `AccountsScreen` or `/accounts*` as live user-facing routes.

- [x] **Step 3: Verify there are no stale `/accounts` route references**

```bash
grep -n "/accounts" AGENTS.md
```

Expected: no live user-facing `/accounts` route references remain. Feature-slice directory references such as `lib/features/accounts/` are allowed and should be reviewed manually if matched.

- [x] **Step 4: Commit**

```bash
git add AGENTS.md
git commit -m "docs(agents): update route guidance for analysis and manage accounts"
```

---

### Task 24: Final verification — full suite and release-gate greps

**Files:**
- None (verification only)

- [x] **Step 1: Run dart format**

```bash
dart format .
```

- [x] **Step 2: Run codegen to ensure generated files are fresh**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

- [x] **Step 3: Run flutter analyze**

```bash
flutter analyze
```

Expected: PASS.

- [x] **Step 4: Run the full test suite**

```bash
flutter test
```

Expected: PASS.

- [x] **Step 5: Run import lint**

```bash
dart run import_lint
```

Expected: PASS.

- [x] **Step 6: Run the release-gate greps**

```bash
grep -rn "'/accounts" lib/ test/
grep -nE "Accounts(/| |$|\.|,|:)" PRD.md
grep -n "/accounts" PRD.md
grep -nE "Accounts(/| |$|\.|,|:)" README.md
grep -n "/accounts" README.md
grep -nE "Accounts(/| |$|\.|,|:)" AGENTS.md
grep -n "/accounts" AGENTS.md
```

Verify all results are in allowed lists.

- [x] **Step 7: Final commit if any generated files changed**

```bash
git add -A
git commit -m "chore: regenerate code after accounts-to-analysis refactor"
```

---

## Summary

| Chunk | Tasks | Description                                                                                     |
|-------|-------|-------------------------------------------------------------------------------------------------|
| 1     | 1–3   | Localization keys, AdaptiveShell label, AnalysisScreen                                          |
| 2     | 4–7   | Preserve existing AccountTile behavior, add ManageAccountsBody/Sheet/Tile, update Settings      |
| 3     | 8     | Router overhaul — replace /accounts branch                                                      |
| 4     | 9–14  | Route migration — fix all callers and stage later cleanup                                       |
| 5     | 15–20 | Test migration plus obsolete-file cleanup                                                       |
| 6     | 21–24 | Documentation updates and final verification                                                    |
