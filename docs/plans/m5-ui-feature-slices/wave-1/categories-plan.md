# M5 Wave 1 — Categories Slice

**Source of truth:** [`PRD.md`](../../../../PRD.md) → *MVP Screens → Categories*, *Default Categories*, *Layout Primitives → Category picker*, *Management Rules*. Contracts inherited from [`wave-0-contracts-plan.md`](../wave-0-contracts-plan.md). Where this plan is silent, defer to those.

Categories owns two surfaces: the management screen at `/settings/categories`, and the `CategoryPicker` that Transactions (Wave 2) will consume.

---

## 1. Goal

Replace the M4 placeholder at `lib/features/categories/categories_screen.dart` with a full management screen, and fill in the Wave 0 `CategoryPicker` skeleton with the real adaptive picker implementation.

All business rules (category type lock, archive-vs-delete, seeded-vs-custom delete policy) are already enforced in `CategoryRepository`. This slice is UI-only — do not re-implement rules in the controller or widgets.

---

## 2. Inputs

| Dependency                   | Purpose                                                                                    | Import path                                  |
|------------------------------|--------------------------------------------------------------------------------------------|----------------------------------------------|
| `categoryRepositoryProvider` | `watchAll(type:, includeArchived:)`, `save`, `rename`, `archive`, `delete`, `isReferenced` | `app/providers/repository_providers.dart`    |
| `icon_registry.dart`         | Resolve `category.icon` → `IconData`                                                       | `core/utils/icon_registry.dart`              |
| `color_palette.dart`         | Resolve `category.color` → `Color`                                                         | `core/utils/color_palette.dart`              |
| `AppLocalizations`           | `category*` display names + new `categories*` UI keys (§3.2)                               | `l10n/app_localizations.dart`                |

The slice **does not** read from any other repository. The slice **does not** import from any other feature.

---

## 3. Deliverables

### 3.1 Files (under `lib/features/categories/`)

- `categories_screen.dart` — replaces the M4 placeholder.
- `categories_controller.dart` — Riverpod `@riverpod class CategoriesController extends _$CategoriesController`. Commands: `renameCategory`, `updateIconColor`, `createCategory`, `archiveCategory`, `undoArchive`, `deleteCategory`, `reorder`.
- `categories_state.dart` — Freezed sealed union (`Loading | Data(expense: List<Category>, income: List<Category>) | Error`). No top-level `Empty` variant — first-run seed guarantees categories exist, but the `Data` variant must still support per-section empty rendering after archive flows. The `Data` variant is always sorted by `sortOrder` (nulls last) → display name ascending.
- `widgets/category_picker.dart` — fill in the Wave 0 skeleton (§2.1). **Keep the top-level `showCategoryPicker` signature exactly as frozen.**
- `widgets/category_form_sheet.dart` — shared add/edit modal sheet.
- `widgets/category_icon_picker.dart` — scrollable grid over `iconRegistry.entries`.
- `widgets/category_color_picker.dart` — grid/row over `colorPalette` indices.
- `widgets/category_tile.dart` — row rendering (icon tile + display name + slidable actions).

Widget classes that are only used inside the slice stay library-private (`_CategoryPickerSheet`, etc.).

### 3.2 ARB keys

Prefix: `categories*` (UI). Do **not** add keys under `category*` — that prefix is reserved for seeded display names (already present).

Minimum new keys (final list discovered during implementation): `categoriesManageTitle`, `categoriesAddCta`, `categoriesSectionExpense`, `categoriesSectionIncome`, `categoriesFormNameLabel`, `categoriesFormIconLabel`, `categoriesFormColorLabel`, `categoriesFormTypeLabel`, `categoriesFormTypeLockedHint`, `categoriesArchiveUndoSnackbar`, `categoriesDeleteConfirmTitle`, `categoriesDeleteConfirmBody`, `categoriesPickerTitleExpense`, `categoriesPickerTitleIncome`, `categoriesPickerEmptyCta`.

Every new key lands in `app_en.arb`, `app_zh_TW.arb`, and `app_zh_CN.arb` in the same commit. `app_zh.arb` stays fallback-only. Every new key carries an `@<key>` description with a PRD line reference.

### 3.3 Tests

- `test/unit/controllers/categories_controller_test.dart` — state transitions (loading → data, data after create/rename/archive/delete/reorder); command error surfacing when repository throws `CategoryTypeLockedException` or `CategoryInUseException`.
- `test/widget/features/categories/categories_screen_test.dart` — grouped sections render in order, per-section empty CTA renders when one type has no visible categories, slidable archive action surfaces undo snackbar, FAB opens the form sheet, 2× text scale survives.
- `test/widget/features/categories/category_picker_test.dart` — picker filters by type, excludes archived, resolves with the tapped category, resolves with `null` on scrim dismiss, empty-state CTA closes the sheet and resolves `null`.

---

## 4. Screen layout (per PRD → Layout Primitives → Constraint rule)

`Scaffold` → `CustomScrollView` with:
- `SliverToBoxAdapter` — Expense section header.
- `SliverList` (or `SliverReorderableList`) — expense categories.
- `SliverToBoxAdapter` — Income section header.
- `SliverList` (or `SliverReorderableList`) — income categories.
- `SliverPadding` — FAB clearance.

FAB opens `category_form_sheet` in Add mode (type defaults to Expense; user toggles).

Each tile uses `flutter_slidable` with:
- Trailing action: **Archive** if `isReferenced(id) == true` OR `l10nKey != null`; else **Delete**. The controller computes this; the widget does not re-query the repository on render.
- Long-press: reorder drag handle.
- Tap: opens form sheet in Edit mode.

If one section becomes empty after archive flows, render that section header plus an inline `categoriesAddCta` affordance for that type. Do not assume both sections remain non-empty forever.

---

## 5. `CategoryPicker` internals (fills Wave 0 §2.1 skeleton)

Entry point: the top-level `showCategoryPicker(BuildContext, {required CategoryType type})` function. **Frozen by Wave 0 — do not change the signature.**

Implementation contract:
- `showCategoryPicker` chooses the container internally: `showModalBottomSheet<Category>` with `isScrollControlled: true` on `<600dp`, constrained dialog on `>=600dp`.
- Picker body in both containers: `CustomScrollView` → `SliverGrid` of category tiles (icon + name).
- Data source: a new family provider (e.g. `@Riverpod(keepAlive: false) Stream<List<Category>> categoriesByType(Ref ref, CategoryType type)`) that internally calls `categoryRepositoryProvider.watchAll(type: type, includeArchived: false)`. Defined in `categories_controller.dart` or a sibling file — not in the widget.
- On tile tap: `Navigator.pop(context, tappedCategory)`.
- On scrim dismiss: Flutter returns `null`. The `show*` function returns whatever `Navigator.pop` returned.
- Empty state: inside the picker container, show a "No categories yet — Create one" CTA that closes the picker (`Navigator.pop(null)`) and resolves `null`. The picker does not navigate on Transactions' behalf; the caller decides whether to open category management / creation flow and whether to re-enter the picker afterward.

Picker tests must cover 2× text scale per `PRD.md` → *Layout Primitives → Constraint rule*.

**Forward-compat:** if a future slice needs optional filtering (e.g. "exclude category id X" for a change-category flow), add named params with defaults that preserve current behavior. Never change the required positional signature.

---

## 6. Add/Edit form (`category_form_sheet.dart`)

Presented as a modal bottom sheet. Fields:

- **Display name** — `TextField`. Writes `customName`. For seeded rows, `l10nKey` is preserved (see PRD → *Default Categories*); for custom rows, `l10nKey` stays `null` and `customName` is authoritative.
- **Icon** — opens `category_icon_picker`. Stored as string key.
- **Color** — opens `category_color_picker`. Stored as int index into `colorPalette`.
- **Type** — segmented control Expense/Income. Enabled only in Add mode; disabled in Edit mode with the inline hint `categoriesFormTypeLockedHint`.

Save enabled when display name is non-empty AND an icon is selected. Color defaults to palette index 0 if the user never opens the picker.

Save path calls the appropriate controller command. Repository exceptions (`CategoryTypeLockedException`, `CategoryInUseException`) surface via `AsyncError` and render inline inside the sheet (not a snackbar — the sheet stays open so the user can retry).

---

## 7. Archive vs delete policy

Repository rules remain authoritative. The controller derives which affordance to show and routes the correct command; it does not create a second source of truth for the policy.

| Condition                                                          | Affordance |
|--------------------------------------------------------------------|------------|
| `isReferenced(id) == true`                                         | Archive    |
| `l10nKey != null` (seeded row), referenced or not                  | Archive    |
| `l10nKey == null` AND `isReferenced(id) == false` (custom, unused) | Delete     |

- After Archive: SnackBar with `commonUndo` action. Controller exposes `undoArchive(id)` which calls `save` with `isArchived: false`.
- After Delete: confirmation dialog (`categoriesDeleteConfirm*`). No undo — `delete` is final. If the user cancels, the row remains.

---

## 8. Cross-slice contract adherence (Wave 0)

- §2.1 — `showCategoryPicker` signature frozen; no extra params in this PR.
- §2.3 — Settings owns the "Manage Categories" link (`/settings/categories`); Categories owns the screen. Do not duplicate the link in Home or elsewhere.
- §2.4 — Do not edit `router.dart`, repositories, or the Drift schema. If a convenience repository method seems useful, raise Platform RFC; do not inline SQL in the controller.
- §2.5 — All supporting widgets live under `lib/features/categories/widgets/`. No `core/widgets/` promotion in MVP.
- §2.7 — Codegen hygiene already landed in Wave 0; do not re-touch `l10n.yaml`.

---

## 9. Out of scope (defer)

- Category merging / bulk operations — not in MVP.
- Per-category visibility toggles beyond `is_archived` — not in MVP.
- Adding new palette colors or new icon keys — append-only surfaces; changes go through Platform, not this slice.
- Phase 2 features (token categories, transfer categories — there are none, per PRD).

---

## 10. Exit criteria

- `categories_screen.dart` renders `Loading`, `Data`, and `Error` variants without errors.
- Create / rename / archive / delete / reorder work end-to-end against the real repository via the in-memory Drift harness in `test/support/test_app.dart`.
- `showCategoryPicker` returns the selected `Category` or `null` on dismiss; filters by type; excludes archived; empty state works.
- 2× text scale test passes on both the screen and the picker sheet.
- `flutter analyze` clean.
- `flutter test` green, including the three tests enumerated in §3.3.

---

## 11. Sequencing

Single agent, single PR:

1. Fill in `widgets/category_picker.dart` (Wave 0 skeleton → real adaptive picker). Write `category_picker_test.dart` first.
2. Implement `categories_state.dart` + `categories_controller.dart`.
3. Implement `widgets/category_tile.dart`, `category_form_sheet.dart`, `category_icon_picker.dart`, `category_color_picker.dart`.
4. Implement `categories_screen.dart`, wiring FAB + slidable actions + reorder.
5. Add ARB keys (§3.2) across `app_en.arb`, `app_zh_TW.arb`, and `app_zh_CN.arb` in the same commit.
6. Write `categories_controller_test.dart` + `categories_screen_test.dart`.
7. Run `dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test` until green.
8. Open PR titled `feat(m5): categories slice`.

---

## 12. Risks

1. **Picker API drift.** Agent is tempted to "just add an optional `preselectedId`" and breaks the Wave 0 freeze. Reject in review; land separately post-Wave-1 only if a real consumer needs it.
2. **Type-lock regression via UI.** If the form allows type editing for an existing category, save throws `CategoryTypeLockedException`. Enforce by disabling the toggle in Edit mode; test the toggle's `enabled` state explicitly.
3. **Delete affordance on seeded rows.** Seeded rows must never show Delete, even if unreferenced — re-seeding would create duplicate rows under a new id. Test: seeded + unreferenced → swipe reveals Archive, not Delete.
4. **Palette/icon mutation via the form.** Do not add controls to create new palette colors or icon keys. Only selection among existing entries.
5. **Category form sheet clipped by keyboard.** Wrap sheet body in `SingleChildScrollView`; widget test with `tester.showKeyboard` to verify.
6. **Picker provider leaks.** `categoriesByType` family provider must not be `keepAlive: true` — the picker disposes on sheet close and should free its subscription.
