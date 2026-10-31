# UI & Layout Primitives

> Authoritative source: [`PRD.md` → *Layout Primitives*](../../PRD.md#layout-primitives) and [`PRD.md` → *Adaptive Layouts*](../../PRD.md#adaptive-layouts).

Layout primitives below cover screens with known unbounded-constraint or keyboard hazards. Follow them.

## Required Widget Trees

- **Home:** `CustomScrollView` with `SliverToBoxAdapter` (day-nav header with prev/next and `Jump to today`) + `SliverToBoxAdapter` (summary strip) + `PendingSection` sliver (auto-hides when no pending rows; cap at 5 visible tiles, rest behind "Show N more") + `SliverList` (selected day's transaction rows). Home shows one day at a time — there is no combined infinite day-list. Never nest `ListView` in `Column`.
- **Add/Edit Transaction:** `Scaffold(resizeToAvoidBottomInset: false)` → `SafeArea` → `Column` with scrollable form `Expanded` above a fixed-height `CalculatorKeypad`. The keypad must not be covered by the soft keyboard.
- **Category picker:** `ModalBottomSheet` (<600dp, 90% height) or `Dialog` (>=600dp) → `CustomScrollView` with, per category type, a `SliverToBoxAdapter` title + `SliverGrid` (five tiles per row).

## Text scale

All scrollable regions must survive **2× text scale**; fixed-height widgets (keypad, splash day counter) clamp at 1.5× or reflow.

## Adaptive Breakpoint

The only adaptive breakpoint is a single threshold at **600dp**, switched at the shell level via `LayoutBuilder`:

- `lib/app/widgets/adaptive_shell.dart` — bottom `NavigationBar` ↔ `NavigationRail`
- `lib/app/router.dart` — `/home/add` + `/home/edit/:id` wrap in `_AdaptiveTransactionFormRoute` so wide layouts render inside a constrained dialog
- `lib/features/categories/widgets/category_picker.dart` — bottom sheet ↔ dialog at the same threshold

## Reference UI slices

Use the live feature screens as the canonical examples of the PRD primitives, not older plan placeholders:

- `lib/features/transactions/transaction_form_screen.dart`
- `lib/features/home/home_screen.dart`
- `lib/features/accounts/account_form_screen.dart`
- `lib/features/recurring/recurring_rules_screen.dart`
- `lib/features/categories/widgets/category_picker.dart`
- `lib/features/home/widgets/pending_section.dart` — canonical delete-with-undo pattern for an in-page section (mirrors `recurring_rules_controller.dart`)
- `lib/features/analysis/charts/widgets/selected_slice_items_list.dart` — chart drill-down items list. Keep it as a **sibling below** the chart body inside `charts_section.dart`; do **not** nest it inside the swipeable chart surface. The widget owns its snackbar/effect wiring and action-only delete rows.
- `lib/features/settings/widgets/manage_accounts_sheet.dart` / `manage_accounts_tile.dart` — account management is opened from Settings via the `ManageAccountsTile` sheet/dialog flow.

Shopping-list routes are under the Home branch (`/home/shopping-list`, `/home/shopping-list/:itemId`) and accessed via the Home shopping-cart FAB; there is no `ShoppingListCard` on the Analysis tab.
