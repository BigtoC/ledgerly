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

The only adaptive breakpoint is a single threshold at **600dp**: a width of 600 or more is wide (`>= 600`). It switches in these places:

- `lib/ui/core/widgets/adaptive_shell.dart` — bottom `NavigationBar` ↔ `NavigationRail`, via `LayoutBuilder`.
- `lib/app/router.dart` — `_AdaptiveFormRoute` renders a form route full-screen below 600dp and inside a centered `Dialog` at most 560dp wide from 600dp, via `LayoutBuilder`. It wraps `/settings/recurring/new`, `/settings/recurring/:id`, `/settings/import` and `/settings/export`, and, through `_AdaptiveTransactionFormRoute`, `/home/add`, `/home/edit/:id` and `/home/shopping-list/:itemId`. The account form routes (`/settings/manage-accounts/new`, `/settings/manage-accounts/:id`) stay full-screen at every width.
- Picker and sheet helpers check `MediaQuery.sizeOf(context).width >= 600` and open a constrained `Dialog` instead of a modal bottom sheet: `lib/ui/features/categories/views/category_picker.dart` (dialog up to 560×600), `lib/ui/features/transactions/views/account_picker_sheet.dart`, `lib/ui/features/settings/views/manage_accounts_sheet.dart` and `lib/ui/features/settings/csv_import/views/csv_account_resolution_sheet.dart` (dialogs up to 480×560).
- `lib/ui/features/recurring/views/recurring_rules_screen.dart` — the one in-screen switch: the extended FAB becomes an `AppBar` add action.

Home is single-pane at every width.

## Reference UI slices

Use the live feature screens as the canonical examples of the PRD primitives, not older plan placeholders:

- `lib/ui/features/transactions/views/transaction_form_screen.dart`
- `lib/ui/features/home/views/home_screen.dart`
- `lib/ui/features/accounts/views/account_form_screen.dart`
- `lib/ui/features/recurring/views/recurring_rules_screen.dart`
- `lib/ui/features/categories/views/category_picker.dart`
- `lib/ui/features/home/views/pending_section.dart` — canonical delete-with-undo pattern for an in-page section (mirrors `recurring_rules_controller.dart`)
- `lib/ui/features/analysis/charts/views/selected_slice_items_list.dart` — chart drill-down items list. Keep it as a **sibling below** the chart body inside `charts_section.dart`; do **not** nest it inside the swipeable chart surface. The widget owns its snackbar/effect wiring and action-only delete rows.
- `lib/ui/features/settings/views/manage_accounts_sheet.dart` / `manage_accounts_tile.dart` — account management is opened from Settings via the `ManageAccountsTile` sheet/dialog flow.

Shopping-list routes are under the Home branch (`/home/shopping-list`, `/home/shopping-list/:itemId`) and accessed via the Home shopping-cart FAB; there is no `ShoppingListCard` on the Analysis tab.
