# M2 — Stream C: Theme wiring + ARB key population

**Owner:** Shell / Core (Dev B in `docs/plans/implementation-plan.md` §8)
**Milestone:** M2 — Core utilities (`docs/plans/implementation-plan.md` §5, M2 row, stream C)
**Sibling streams (M2):**
- Stream A: `money_formatter.dart`, `date_helpers.dart`, unit tests (not blocking this stream).
- Stream B: `icon_registry.dart`, `color_palette.dart`, seeded icon/color key list (soft-coupled — see §10 "Seed contract cross-reference").

**Authoritative PRD ranges:** [`PRD.md`](../../../PRD.md)
- Default Expense Categories — lines **459–478**
- Default Income Categories — lines **479–491**
- Default Account Types — lines **495–506**
- Splash Screen section — lines **510–552** (default display text, button label, `Since {date}` template, settings labels)
- MVP Screens & User Flow — lines **652–749** (nav tabs, Home empty state, CTA, screen states)
- Internationalization — lines **864–887** (ARB structure, base `app_zh.arb` required, rename non-translation rule)
- Theme section — lines **891–899** (`ColorScheme.fromSeed()` light + dark, `user_preferences` theme storage)

**Style template:** `docs/plans/m1-data-foundations/stream-c-field-name-contract.md` — contract-heavy tables + change-control rules. This plan mirrors that density for the ARB key inventory.

---

## 1. Purpose

This stream freezes two things downstream work depends on:

1. **Material 3 theme constants** — `lightTheme` / `darkTheme` ThemeData plus the two `ColorScheme` objects they consume, with a single named seed color chosen from the MD3 baseline so future additions (accents, dark tweaks) have a documented origin.
2. **ARB key inventory** — every user-facing string the app shell, splash, seed, and shared UI labels need, populated in `app_en.arb`, `app_zh_TW.arb`, `app_zh_CN.arb` with a minimal `app_zh.arb` kept alive as the codegen fallback (see CLAUDE.md → *Dependency Pins* → "Chinese ARBs require a base `app_zh.arb`").

The stream exists because three unrelated downstream consumers all need the same set of strings and the same ThemeData object, and letting each M5 slice invent its own keys would cause (a) duplicate keys in different casing (`category.food` vs `Category.Food`), (b) drift between M3 seed `l10n_key`s and what M5 widgets look up, and (c) MaterialApp theme forks per feature.

**Change control.** Any ARB key rename or addition touches **all three locales** in the same PR (implementation-plan.md §8 cross-cutting ownership). Any theme-token change touches both `color_schemes.dart` and any golden-test `matchesGoldenFile` fixtures generated downstream. Unilateral edits are forbidden.

**Out of scope (deliberately):**
- `money_formatter.dart`, `date_helpers.dart` — Stream A.
- `icon_registry.dart`, `color_palette.dart` — Stream B.
- Theme provider (`themeModeProvider`) watching `user_preferences` — M4 (`app/app.dart`, `app/bootstrap.dart`).
- Locale provider wiring `MaterialApp.locale` — M4.
- Feature-specific screen labels used by exactly one M5 slice (see §7 "Scope boundary for screen-specific labels").
- `pubspec.yaml` edits — already correct from M0 (`flutter_localizations`, `intl ^0.20.2` pinned).
- `flutter_native_splash` regeneration — M6.

---

## 2. Current-state quotation

### 2.1 `l10n/app_en.arb` (today)

```json
{
  "@@locale": "en",
  "appTitle": "Ledgerly",
  "@appTitle": {
    "description": "Application title shown on the launcher and in the app bar."
  }
}
```

### 2.2 `l10n/app_zh.arb` (today — base fallback)

```json
{
  "@@locale": "zh",
  "appTitle": "Ledgerly"
}
```

### 2.3 `l10n/app_zh_TW.arb` (today)

```json
{
  "@@locale": "zh_TW",
  "appTitle": "Ledgerly"
}
```

### 2.4 `l10n/app_zh_CN.arb` (today)

```json
{
  "@@locale": "zh_CN",
  "appTitle": "Ledgerly"
}
```

### 2.5 `lib/core/theme/app_theme.dart` (today)

```dart
// TODO(M2): Define `lightTheme` and `darkTheme` using `ColorScheme.fromSeed()`
// per PRD -> Theme. A Riverpod provider watches `user_preferences` and
// rebuilds MaterialApp on theme change.
```

### 2.6 `lib/core/theme/color_schemes.dart` (today)

```dart
// TODO(M2): Seeded MD3 ColorScheme definitions for light + dark, per
// PRD -> Theme. Splash visuals (sun background, rainbow gradient) are
// intentionally independent of this scheme.
```

### 2.7 `l10n.yaml` (today — unchanged by this stream)

```yaml
arb-dir: l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

Confirmed sane: template is `app_en.arb`, generated class is `AppLocalizations`, `nullable-getter: false` means every added getter must be present in the template at generation time (blocks typo'd lookups at compile time).

### 2.8 `pubspec.yaml` (relevant lines — unchanged by this stream)

```yaml
flutter_localizations:
  sdk: flutter
intl: ^0.20.2
flutter:
  uses-material-design: true
  generate: true
```

No dependency edits are part of this stream.

---

## 3. ARB naming conventions (binding)

| Space | Rule | Example |
|---|---|---|
| Key casing | `camelCase` for the top-level key | `splashEnter`, `commonSave` |
| Namespacing | Dotted prefix inside the key string is **not used**; `flutter_localizations` maps each key to a Dart getter, and dots are illegal. Use camelCase prefixes: `categoryFood`, `accountTypeCash`, `commonSave`, `splashEnter`, `navHome`. | `categoryFoodGroceries` (not `category.food.groceries`) |
| `l10n_key` (DB column) | The string stored in `categories.l10n_key` and `account_types.l10n_key`. PRD writes these as `category.food`, `accountType.cash` (dotted). **Keep PRD dotted form for the DB value.** The ARB getter name is the camelCase transformation of the dotted path. Mapping is done in `AppLocalizations` (generated) by the seed contract (see §10). | DB: `category.food.groceries` → ARB getter: `categoryFoodGroceries` |
| Placeholder syntax | ICU `{name}` with `@key.placeholders` block declaring `type: String` / `type: DateTime` / `type: int` and, for dates, a `format` key. | `{date}` with `"format": "yMMMMd"` |
| Description | Every new `@key` entry in `app_en.arb` carries a `description` field. Chinese ARBs omit `@key` metadata (`intl_translation` treats the template as canonical). | `"description": "Splash default display text, inserts localized date."` |

**PRD-to-ARB key mapping convention for seeded categories.** PRD spells category keys with dots (`category.food`, `category.drinks.coffee`). Dotted keys cannot be Dart identifiers, so the ARB key is the camelCase concatenation: `category.food` → `categoryFood`; `category.drinks.coffee` → `categoryDrinksCoffee`; `accountType.cash` → `accountTypeCash`. The seed (M3) writes the **dotted form** into `categories.l10n_key` / `account_types.l10n_key`. The M5 category/account rendering looks up via a helper (see §7.3) that maps dotted DB keys → ARB getters.

**Locked decision:** no locale-specific `fieldRename`, no `@@x-` extension keys, no plural/gender selectors in M2. Plurals arrive per-slice in M5 only if a screen needs them (e.g. `"You have {count,plural,...}"`).

---

## 4. Theme decisions

### 4.1 Seed color choice

**Chosen seed color:** `Color(0xFF006C35)` — **Green 40** from the MD3 baseline palette (https://m3.material.io/styles/color/static/baseline).

**Why this specific shade.**
1. It is already pinned into `core/utils/color_palette.dart` (Stream B) because PRD 464 assigns Green 40 `#006C35` to the `Drinks` seeded category. Re-using a palette-registered hex as the seed avoids a second MD3 color index.
2. Green reads as "money/ledger" at a glance without being the overt `Material.blue` default that ships in every Flutter tutorial — Ledgerly is an expense tracker, not a generic material sample.
3. `ColorScheme.fromSeed()` expands one seed into the full Material 3 tonal palette, so nothing about picking Green 40 restricts future accents — error / success / tertiary are derived, not hand-picked.
4. The splash screen's rainbow-gradient date text (PRD 525) and sun-themed background (PRD 523) are **intentionally outside the theme** per PRD 899, so the seed color does not need to coordinate with splash visuals.

Alternative seeds considered and rejected:
- `#B3251E` Red 60 (Food): red reads as error/alarm — wrong semantic for a neutral shell.
- `#04409F` Blue 30 (3C): too close to Material default blue; loses distinctiveness.
- `#FCBD00` Yellow 80 (income): too saturated at scaled-up surface tones; dark-mode surfaces get muddy.

**Alternative to revisit in M6.** If user testing in M6 shows Green 40 reads too "neutral cash-register" and not "personal ledger," revisit then — M2 makes a defensible default, not a permanent one.

### 4.2 ColorScheme invocations

Exact invocations to be written into `lib/core/theme/color_schemes.dart`:

```dart
// ...file header...
const _seed = Color(0xFF006C35); // MD3 Baseline — Green 40. See PRD 464.

final lightColorScheme = ColorScheme.fromSeed(
  seedColor: _seed,
  brightness: Brightness.light,
);

final darkColorScheme = ColorScheme.fromSeed(
  seedColor: _seed,
  brightness: Brightness.dark,
);
```

Both are `final`, top-level, no build-context dependency. They are imported by `app_theme.dart` only.

### 4.3 ThemeData knobs

Exact shape of `lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'color_schemes.dart';

ThemeData _base(ColorScheme scheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    typography: Typography.material2021(platform: defaultTargetPlatform),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
  );
}

final lightTheme = _base(lightColorScheme);
final darkTheme  = _base(darkColorScheme);
```

| Knob            | Value                                   | Rationale                                                                                                                  |
|-----------------|-----------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| `useMaterial3`  | `true`                                  | PRD 893 mandates MD3.                                                                                                      |
| `colorScheme`   | Injected scheme                         | The single source of visible color.                                                                                        |
| `typography`    | `Typography.material2021`               | MD3-aligned type scale; avoids the 2014 legacy `Typography.material2014` that Flutter still defaults to on some platforms. |
| `visualDensity` | `VisualDensity.adaptivePlatformDensity` | Lets tablet (≥600dp, per CLAUDE.md Layout Primitives) loosen tap targets without widget-level overrides.                   |
| `iconTheme`     | `onSurface` / size 24                   | Registry icons (Stream B) come in at a single default rather than random per-widget `Icon(size: ...)` calls.               |

**Deliberately NOT set (left at MD3 defaults):**
- `textTheme` — Material 2021 typography already handles the full scale.
- `appBarTheme`, `bottomNavigationBarTheme`, `navigationRailTheme`, `floatingActionButtonTheme`, `dialogTheme`, `inputDecorationTheme` — per-widget overrides are **M5** territory. Overriding them here would force every M5 slice to unpick a shell default; instead M2 ships the bare minimum and M5 slices add theme extensions if warranted.
- `pageTransitionsTheme` — M4 router chooses per-route transitions (`CustomTransitionPage` for splash); a global override would fight that.
- `splashFactory`, `materialTapTargetSize` — accept MD3 defaults.

**Not relevant here:** no `ThemeExtension` is defined in this stream. If a slice needs a typed extension (e.g. category-tile surface tint) it ships that extension alongside its feature folder in M5.

---

## 5. ARB key inventory

### 5.1 Scope of what this stream adds

Four groups of keys ship in this stream. Keys that belong to a single M5 slice and are not referenced by any shared widget are deferred — see §7.3.

- **Group S (Shell / Navigation / Common)** — bottom-nav labels, app-wide snackbars/CTAs, shared verb labels (Save, Cancel, Delete, Archive, Edit, Undo), Home empty-state text, first-run CTA.
- **Group P (Splash / Settings for splash)** — splash defaults (`splashEnter`, `splashSinceDate`, day-counter label) plus splash settings-screen labels referenced on the Settings screen M5 slice.
- **Group C (Seeded categories)** — every expense + income seeded category from PRD 459–491.
- **Group A (Seeded account types)** — `accountTypeCash`, `accountTypeInvestment` from PRD 497–499.

Plus `appTitle` stays as-is — already seeded in M0.

### 5.2 Key inventory — Group S (Shell / Common)

`key | usage | EN string`

| Key                       | Usage                                                                              | EN                                      |
|---------------------------|------------------------------------------------------------------------------------|-----------------------------------------|
| `navHome`                 | Bottom-nav tab 1 (PRD 656)                                                         | Home                                    |
| `navAccounts`             | Bottom-nav tab 2 (PRD 656)                                                         | Accounts                                |
| `navSettings`             | Bottom-nav tab 3 (PRD 656)                                                         | Settings                                |
| `commonSave`              | Primary CTA in Add/Edit Transaction, Accounts form, Categories form, Settings form | Save                                    |
| `commonCancel`            | Form dismiss, confirm-discard dialog negative action                               | Cancel                                  |
| `commonDelete`            | Swipe action and confirm dialog                                                    | Delete                                  |
| `commonArchive`           | List swipe, category/account archive action (PRD Management Rules 737)             | Archive                                 |
| `commonEdit`              | Row overflow, Add/Edit screen title when editing                                   | Edit                                    |
| `commonUndo`              | Undo snackbar after delete (PRD 695)                                               | Undo                                    |
| `commonDiscard`           | Confirm-discard dialog positive action (PRD 689)                                   | Discard                                 |
| `commonAdd`               | Create affordances (accounts, categories)                                          | Add                                     |
| `commonDone`              | Modal close affordance (picker sheet)                                              | Done                                    |
| `transactionTypeExpense`  | Expense/income segmented control (PRD 683)                                         | Expense                                 |
| `transactionTypeIncome`   | Expense/income segmented control (PRD 683)                                         | Income                                  |
| `homeEmptyTitle`          | Home empty-state title (PRD 695)                                                   | No transactions yet                     |
| `homeEmptyCta`            | Home empty-state primary CTA (PRD 666)                                             | Log first transaction                   |
| `homeFabLabel`            | Home FAB semantics label (PRD 657)                                                 | Add transaction                         |
| `homeSummaryTodayExpense` | Home summary strip row (PRD 672)                                                   | Today expense                           |
| `homeSummaryTodayIncome`  | Home summary strip row (PRD 672)                                                   | Today income                            |
| `homeSummaryMonthNet`     | Home summary strip row (PRD 672)                                                   | Month net                               |
| `errorSnackbarGeneric`    | Save-failure snackbar (PRD 690, 696)                                               | Something went wrong. Please try again. |

**Note on Group S scope.** These are the strings referenced either (a) by the app shell (nav, MaterialApp), (b) by the Home screen's first-run/empty state that M4 shows as a placeholder and M5 finishes, or (c) by verbs reused across ≥ 2 slices (Save/Cancel/Delete/Archive/Edit/Undo/Discard/Add/Done). Slice-only verbs are deferred.

### 5.3 Key inventory — Group P (Splash + splash Settings labels)

| Key                         | Usage                                                           | EN                 |
|-----------------------------|-----------------------------------------------------------------|--------------------|
| `splashEnter`               | Default "Enter" button label (PRD 527, 547)                     | Enter              |
| `splashSinceDate`           | Default display text template (PRD 526, 546); ICU with `{date}` | Since {date}       |
| `splashDayCountLabel`       | Day-counter secondary label on splash (PRD 551)                 | days               |
| `settingsSplashSection`     | Settings section header for splash group (PRD 544)              | Splash screen      |
| `settingsSplashEnabled`     | Toggle label (PRD 544)                                          | Show splash screen |
| `settingsSplashStartDate`   | Date-picker label (PRD 545)                                     | Start date         |
| `settingsSplashDisplayText` | Free-text field label (PRD 546)                                 | Display text       |
| `settingsSplashButtonLabel` | Free-text field label (PRD 547)                                 | Button label       |

`splashSinceDate` is an ICU template; the `@splashSinceDate` template block declares:

```json
"@splashSinceDate": {
  "description": "Splash default display text. {date} is formatted locale-aware via intl.",
  "placeholders": {
    "date": { "type": "DateTime", "format": "yMMMMd" }
  }
}
```

`{days}` from PRD 526 is **not** a placeholder on `splashSinceDate` — PRD 526 describes `splash_display_text` as a user-customizable template where the USER may insert `{date}` and `{days}` tokens. The localized default only substitutes `{date}`; the runtime text engine resolves `{days}` separately against the current day count. That substitution policy is owned by the Splash M5 slice, not by the ARB.

**Why `settingsSplashSection` is in this stream even though Settings is an M5 slice.** The Settings split-labels for splash are referenced by `SettingsScreen` in M5, but because they describe the *splash feature* (shipped here), their EN/zh texts live with the splash label set. The alternative — letting M5 Settings add them — risks a Settings author renaming "Start date" to "Begin date" and orphaning the splash feature's own documentation. Bundling them here locks the vocabulary.

### 5.4 Key inventory — Group C (Seeded categories)

Covers PRD **459–491** exactly for seeded categories. Each row captures **ARB key** (camelCase) ← → **DB `l10n_key`** (dotted, as PRD writes it) ← → **EN string**.

| ARB key                    | DB `l10n_key` (dotted)       | EN             |
|----------------------------|------------------------------|----------------|
| `categoryFood`             | `category.food`              | Food           |
| `categoryDrinks`           | `category.drinks`            | Drinks         |
| `categoryTransportation`   | `category.transportation`    | Transportation |
| `categoryShopping`         | `category.shopping`          | Shopping       |
| `categoryHousing`          | `category.housing`           | Housing        |
| `categoryEntertainment`    | `category.entertainment`     | Entertainment  |
| `categoryMedical`          | `category.medical`           | Medical        |
| `categoryEducation`        | `category.education`         | Education      |
| `categoryPersonal`         | `category.personal`          | Personal       |
| `categoryTravel`           | `category.travel`            | Travel         |
| `categoryThreeC`           | `category.threeC`            | 3C             |
| `categoryMiscellaneous`    | `category.miscellaneous`     | Miscellaneous  |
| `categoryOther`            | `category.other`             | Other          |
| `categoryIncomeSalary`     | `category.income.salary`     | Salary         |
| `categoryIncomeFreelance`  | `category.income.freelance`  | Freelance      |
| `categoryIncomeInvestment` | `category.income.investment` | Investment     |
| `categoryIncomeGift`       | `category.income.gift`       | Gift           |
| `categoryIncomeOther`      | `category.income.other`      | Other Income   |

**Note — `categoryIncomeInvestment` vs `accountTypeInvestment`.** Both exist and do not collide: one is an income category (PRD 487), the other is an account type (PRD 500). The displayed English label is identical; the keys stay distinct.

**Note — `category.threeC`.** The canonical seeded key is `category.threeC`. The ARB getter is `categoryThreeC`, which keeps the generated Dart identifier readable while preserving the dotted DB key used by seed data.

### 5.5 Key inventory — Group A (Seeded account types)

| ARB key                 | DB `l10n_key`            | EN         |
|-------------------------|--------------------------|------------|
| `accountTypeCash`       | `accountType.cash`       | Cash       |
| `accountTypeInvestment` | `accountType.investment` | Investment |

EN strings match PRD 499–500 word-for-word.

### 5.6 Full inventory summary

Count check:
- Group S: 21 keys
- Group P: 8 keys
- Group C: 18 keys (13 expense categories + 5 income categories)
- Group A: 2 keys

**Total new keys: 49.** Plus `appTitle` (kept from M0) = 50 keys in the finished `app_en.arb`.

---

## 6. ARB inventory — Chinese translations

`key | zh_TW | zh_CN`

Trad. ⇄ Simplified lexical differences are real; the table deliberately does not copy-paste zh_TW into zh_CN. When the character glyph differs between scripts but the word is identical (e.g. 錢包 vs 钱包), both columns are filled; when the word itself is locale-specific (e.g. 計程車 Taiwan vs 出租车 mainland), each column reflects local usage.

### 6.1 Group S — Shell / Common

| Key                       | zh_TW       | zh_CN    |
|---------------------------|-------------|----------|
| `navHome`                 | 首頁          | 首页       |
| `navAccounts`             | 帳戶          | 账户       |
| `navSettings`             | 設定          | 设置       |
| `commonSave`              | 儲存          | 保存       |
| `commonCancel`            | 取消          | 取消       |
| `commonDelete`            | 刪除          | 删除       |
| `commonArchive`           | 封存          | 归档       |
| `commonEdit`              | 編輯          | 编辑       |
| `commonUndo`              | 復原          | 撤销       |
| `commonDiscard`           | 捨棄          | 放弃       |
| `commonAdd`               | 新增          | 添加       |
| `commonDone`              | 完成          | 完成       |
| `transactionTypeExpense`  | 支出          | 支出       |
| `transactionTypeIncome`   | 收入          | 收入       |
| `homeEmptyTitle`          | 尚無交易紀錄      | 暂无交易记录   |
| `homeEmptyCta`            | 記錄第一筆交易     | 记录第一笔交易  |
| `homeFabLabel`            | 新增交易        | 添加交易     |
| `homeSummaryTodayExpense` | 今日支出        | 今日支出     |
| `homeSummaryTodayIncome`  | 今日收入        | 今日收入     |
| `homeSummaryMonthNet`     | 本月淨額        | 本月净额     |
| `errorSnackbarGeneric`    | 發生錯誤，請再試一次。 | 出错了，请重试。 |

### 6.2 Group P — Splash and Splash Settings

| Key                         | zh_TW      | zh_CN      |
|-----------------------------|------------|------------|
| `splashEnter`               | 進入         | 进入         |
| `splashSinceDate`           | 自 {date} 起 | 自 {date} 起 |
| `splashDayCountLabel`       | 天          | 天          |
| `settingsSplashSection`     | 啟動畫面       | 启动页        |
| `settingsSplashEnabled`     | 顯示啟動畫面     | 显示启动页      |
| `settingsSplashStartDate`   | 起始日期       | 起始日期       |
| `settingsSplashDisplayText` | 顯示文字       | 显示文字       |
| `settingsSplashButtonLabel` | 按鈕文字       | 按钮文字       |

The translated `splashSinceDate` value keeps the same `{date}` token in both Chinese ARBs. The `@splashSinceDate` placeholder metadata lives in `app_en.arb` only, which is enough for `gen_l10n` to generate the shared method signature.

### 6.3 Group C — Seeded categories

| Key                        | zh_TW | zh_CN |
|----------------------------|-------|-------|
| `categoryFood`             | 飲食    | 饮食    |
| `categoryDrinks`           | 飲料    | 饮料    |
| `categoryTransportation`   | 交通    | 交通    |
| `categoryShopping`         | 購物    | 购物    |
| `categoryHousing`          | 居住    | 居住    |
| `categoryEntertainment`    | 娛樂    | 娱乐    |
| `categoryMedical`          | 醫療    | 医疗    |
| `categoryEducation`        | 教育    | 教育    |
| `categoryPersonal`         | 個人    | 个人    |
| `categoryTravel`           | 旅遊    | 旅游    |
| `categoryThreeC`           | 3C    | 3C    |
| `categoryMiscellaneous`    | 雜項    | 杂项    |
| `categoryOther`            | 其他    | 其他    |
| `categoryIncomeSalary`     | 薪資    | 工资    |
| `categoryIncomeFreelance`  | 接案    | 自由职业  |
| `categoryIncomeInvestment` | 投資    | 投资    |
| `categoryIncomeGift`       | 餽贈    | 馈赠    |
| `categoryIncomeOther`      | 其他收入  | 其他收入  |

### 6.4 Group A — Seeded account types

| Key                     | zh_TW | zh_CN |
|-------------------------|-------|-------|
| `accountTypeCash`       | 現金    | 现金    |
| `accountTypeInvestment` | 投資    | 投资    |

### 6.5 Cross-table audit

Both the EN table (§5) and the zh_TW/zh_CN table (§6) list the identical stream-owned keys, in the same order. Any PR that adds a new key to one must add it to both — the task checklist in §8 enforces this.

---

## 7. `app_zh.arb` base-fallback rule

### 7.1 CLAUDE.md pin — quoted

CLAUDE.md → *Dependency Pins*:

> **Chinese ARBs require a base `app_zh.arb`.** `flutter_localizations` fails codegen with "Arb file for a fallback, zh, does not exist" when only `app_zh_CN.arb` / `app_zh_TW.arb` are present. Keep `app_zh.arb` in `l10n/` even if it only contains `appTitle` — removing it breaks `flutter pub get`.

### 7.2 What `app_zh.arb` MUST contain

Exactly — and only — the one key required to keep codegen happy:

```json
{
  "@@locale": "zh",
  "appTitle": "Ledgerly"
}
```

**Do NOT promote any Group S/P/C/A keys into `app_zh.arb`.** Rationale: if the bare `zh` file contains e.g. `categoryFood`, then a user on a device reporting `zh-HK` (Cantonese) or any unspecified Chinese locale would fall back to `app_zh.arb` and see a string the maintainers never reviewed. Keeping the `zh` fallback minimal is safe because M4 explicitly resolves Chinese locales before fallback: `zh_TW`, `zh_HK`, `zh_MO`, and other Traditional Chinese locales resolve to `zh_TW`; `zh_CN`, `zh_SG`, and other Simplified Chinese locales resolve to `zh_CN`; ambiguous Chinese locales fall back to English.

### 7.3 Scope boundary for screen-specific labels

**Principle.** Slice-only labels are added per-slice in M5 under implementation-plan.md §8: "Author adds keys in all three files in the same PR." This stream ships only strings referenced by ≥ 2 consumers OR by the shell OR by seed.

Examples of what stays in M5:
- Add/Edit Transaction screen's keypad button labels (if any beyond digits), memo placeholder, date-picker label → M5 Transactions slice.
- Categories management screen's empty state "No categories yet" → M5 Categories slice.
- Accounts management screen's "Set as default" toggle → M5 Accounts slice.
- Settings screen items unrelated to splash (Theme toggle label, Language selector header, Default currency label) → M5 Settings slice.

If two slices discover they want the same label (e.g. "Category" as a section header in both Categories and Add/Edit), they negotiate: the first to land adds it to `commonCategory`; the second imports from `commonCategory` rather than duplicating. Review catches the duplication.

**`l10n_key` lookup helper** (owned by this stream so the naming is predictable): a tiny `localizedCategoryName(AppLocalizations l10n, String dottedKey)` function maps `category.food` → `l10n.categoryFood` and `category.threeC` → `l10n.categoryThreeC`. The helper lives in `core/utils/` and ships as part of Stream C's contract because this stream owns the ARB key naming.

---

## 8. TDD tasks (bite-sized)

Each task is one PR-sized unit. Tests land with the task that introduces the code they cover.

### Task 8.1 — Quote current state and land skeleton ARB template

- **Goal:** `app_en.arb` declares every Group S key with description stubs. Chinese ARBs each add the same keys with placeholder English copy (intentionally wrong, to be overwritten in Task 8.3 / 8.4). `app_zh.arb` untouched.
- **Red:** write a widget test `test/widget/smoke/app_localizations_groups_test.dart` that builds a minimal `MaterialApp` with `AppLocalizations.delegate` and asserts `AppLocalizations.of(context).navHome` is non-null for EN, zh_TW, zh_CN. The test fails because the keys do not exist yet.
- **Green:** add all Group S keys to `app_en.arb` (with `@key` descriptions) and to `app_zh_TW.arb` / `app_zh_CN.arb` (with English placeholder text — the test only asserts non-null).
- **Codegen:** run `flutter pub get` (which triggers `flutter_localizations` codegen when `generate: true`), confirm `l10n/app_localizations.dart` compiles. If `flutter pub get` does not refresh the generator on your machine, run `flutter gen-l10n` explicitly.
- **Commit:** message prefix `l10n(shell):`; stage only `l10n/app_{en,zh_TW,zh_CN}.arb` and the smoke test file. Do NOT commit `.dart_tool/` (gitignored).

### Task 8.2 — Theme files

- **Goal:** `color_schemes.dart` exports `lightColorScheme` / `darkColorScheme` derived from `Color(0xFF006C35)`; `app_theme.dart` exports `lightTheme` / `darkTheme` ThemeData. TODO comments replaced with the §4.2 / §4.3 contents.
- **Red:** `test/widget/theme/theme_smoke_test.dart` — build `MaterialApp(theme: lightTheme, darkTheme: darkTheme, home: Scaffold())` and `pumpWidget`; assert `tester.widget<MaterialApp>(find.byType(MaterialApp)).theme?.useMaterial3 == true` and the colorScheme brightness matches the expected one. Test fails at compile time because `lightTheme` / `darkTheme` don't exist yet.
- **Green:** implement §4.2 and §4.3 files.
- **No goldens.** Widget test asserts structural facts (useMaterial3, colorScheme brightness) only. The splash-screen golden is an M5 concern (implementation-plan.md §5 M5 Splash row).
- **Commit:** `theme:` prefix; stage `lib/core/theme/*.dart` plus the widget test.

### Task 8.3 — Populate Group C (seeded categories) in all three ARBs

- **Goal:** every key in §5.4 / §6.3 present in `app_en.arb`, `app_zh_TW.arb`, `app_zh_CN.arb`. Descriptions live only in EN.
- **Red:** extend the smoke test to assert `AppLocalizations.of(context).categoryFood` etc. are non-null for each of three locales. Pick one sentinel per seeded category family to keep the test readable.
- **Green:** add all 18 keys to EN with strings from §5.4 and descriptions naming the PRD line (e.g. `"PRD 464, seeded expense category 'Drinks'"`). Add the same 18 keys to zh_TW with §6.3 column 2 and to zh_CN with §6.3 column 3.
- **Codegen:** `flutter pub get` (or `flutter gen-l10n`). Verify generated file includes the additional getter methods per locale.
- **Commit:** `l10n(seed-categories):` prefix.

### Task 8.4 — Populate Group A (account types) and Group P (splash + splash settings)

- **Goal:** §5.5, §5.3 / §6.2, §6.4 keys present.
- **Red:** smoke test asserts `accountTypeCash`, `accountTypeInvestment`, `splashEnter`, `splashSinceDate(DateTime(2024, 1, 1))` non-null. The `splashSinceDate` call exercises the ICU placeholder; if the placeholder block is missing or the `format` is wrong, generation fails at build time.
- **Green:** add keys per §5.3 / §5.5 / §6.2 / §6.4. Include the `@splashSinceDate` placeholder block in EN only (Chinese ARBs carry the value but not the `@` metadata, per ARB conventions).
- **Codegen:** `flutter pub get`; verify `AppLocalizations.splashSinceDate` has signature `String splashSinceDate(DateTime date)` in the generated localization output under `l10n/`.
- **Commit:** `l10n(splash+account-types):` prefix.

### Task 8.5 — Backfill Group S Chinese translations

- **Goal:** Group S keys in zh_TW / zh_CN now hold §6.1 strings (not the placeholder-English copies from Task 8.1).
- **Red:** none — the smoke test from 8.1 still asserts non-null. No test should assert exact string content (translators rewrite copy; tests that pin "儲存" as the EN string would become brittle).
- **Green:** overwrite Group S zh_TW / zh_CN values.
- **Manual verification (not automated):** a reviewer fluent in Chinese signs off on the §6.1 table before merge. If no reviewer is available, the plan lists the keys as `"TODO_ZH_TW"` / `"TODO_ZH_CN"` and that landing task is explicitly in-PR follow-up.
- **Commit:** `l10n(shell-zh):` prefix.

### Task 8.6 — Audit pass

- **Goal:** single commit that verifies totals and invariants.
- **Red / tooling:** a short test `test/unit/l10n/arb_audit_test.dart` parses all four ARB files as JSON and asserts:
  1. Every key present in `app_en.arb` (excluding `@`-prefixed metadata) is present in `app_zh_TW.arb` and `app_zh_CN.arb`.
  2. No key is present in `app_zh_TW.arb` or `app_zh_CN.arb` that is absent in `app_en.arb`.
  3. `app_zh.arb` contains exactly one key: `appTitle`.
  4. `app_en.arb` contains all stream-owned keys from §5.2–§5.5, plus `appTitle`.
- **Green:** any drift uncovered is fixed in the same PR.
- **Commit:** `l10n(audit):` prefix. This test becomes a standing regression guard — any future key addition has to keep the three-way parity, or CI fails.

### Task 8.7 — Final `flutter pub get` + `flutter analyze` + `flutter test`

- Runs everything together; fix any generated-file staleness (the most common failure: `AppLocalizations` lagging the ARB because `pub get` wasn't re-run after a rebase). Everything green is the exit criterion.

### 8.8 — Codegen command reference (copy into PR description)

```bash
flutter pub get
# triggers flutter_localizations codegen when pubspec.yaml has `generate: true` (line 69)
flutter gen-l10n
# explicit invocation if the above does not regenerate
flutter analyze
flutter test test/widget/theme/theme_smoke_test.dart
flutter test test/widget/smoke/app_localizations_groups_test.dart
flutter test test/unit/l10n/arb_audit_test.dart
```

Every PR in this stream runs the full sequence locally before `git push`. The generated `app_localizations*.dart` files live under `l10n/` in this repo and should stay in sync with the ARBs. Do not edit the generated files by hand.

---

## 9. Exit criteria

Maps to `docs/plans/implementation-plan.md` §5 M2 exit criteria row for stream C:

| Criterion                                                                                                   | Verification                                                                                  |
|-------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| `lightTheme` and `darkTheme` compile and are importable from `lib/core/theme/app_theme.dart`                | `flutter analyze` green; `theme_smoke_test.dart` green                                        |
| `ColorScheme.fromSeed(...)` invocation is concrete (no TBD seed)                                            | §4.1 commits to `0xFF006C35`; color_schemes.dart ships that literal                           |
| All three target ARBs (`en`, `zh_TW`, `zh_CN`) contain every Group S/P/C/A key                              | `arb_audit_test.dart` passes (Task 8.6)                                                       |
| `app_zh.arb` preserved with at least `appTitle`                                                             | `arb_audit_test.dart` assertion 3 passes                                                      |
| Chinese locale resolution is explicit and tested in M4                                                      | M4 shell test covers Traditional → `zh_TW`, Simplified → `zh_CN`, ambiguous Chinese → English |
| `flutter pub get` → `flutter gen-l10n` round-trip produces a compiling `AppLocalizations` class             | Task 8.7 clean                                                                                |
| Theme preview builds (implementation-plan.md §5 M2 "Theme preview builds (manual verification)")            | Run `flutter run` on any attached device; Scaffold opens without assertion failures           |
| No theme knob is set that M5 slices will have to unpick                                                     | §4.3 documents the allowlist; review enforces                                                 |
| PRD 459–491 (categories) and 497–500 (account types) are 1:1 covered in EN + zh_TW + zh_CN                  | §5.4, §5.5, §6.3, §6.4 checked against PRD line-by-line                                       |
| Splash default strings (`splashEnter`, `splashSinceDate`) present with ICU placeholder on `splashSinceDate` | §5.3 / §6.2 + Task 8.4 red test                                                               |

---

## 10. Seed contract cross-reference (Stream B coordination)

**The seeded `l10n_key` list must match Stream B's icon/color seed contract key-for-key.** PRD 460–491 lists categories by display name + color; Stream B's plan (`docs/plans/m2-core-utilities/stream-b-icons-colors.md`) translates those rows into `(l10nKey, iconKey, colorPaletteIndex)` tuples that M3 seeds into the `categories` table.

**Key-set equivalence rule.** For every row M3 seeds, there MUST exist:
1. An entry in Stream B's tuple list that names the same dotted `l10n_key`.
2. An entry in this stream's §5.4 / §5.5 table that names the same dotted key in the "DB `l10n_key`" column.
3. Three translations in `app_en.arb` / `app_zh_TW.arb` / `app_zh_CN.arb` under the camelCase-transformed ARB key.

If any of the three is missing, M3 seed either writes a row with an `l10n_key` nobody can render (silent UI bug: the category shows a blank name in the picker) or M5 category picker looks up a key that does not exist (generated `AppLocalizations` throws).

### 10.1 Coordination checkpoint

- **Day 1 of M2:** Stream B's author publishes the `(l10nKey, iconKey, colorPaletteIndex)` list for every row in PRD 459–506 (now in `stream-b-icons-colors.md` §4).
- **Day 1 of M2:** Stream C's author reads Stream B's list, diffs it against this plan's §5.4 / §5.5, and either (a) reconciles keys here if Stream B found a typo in the PRD, or (b) opens a correction PR against Stream B's plan.
- **Before either stream merges:** a three-way diff (PRD 459–506 ⇄ Stream B tuples ⇄ Stream C ARB keys) shows zero missing and zero extras.

A `docs/plans/m2-core-utilities/seed-key-contract.md` co-owned doc is an option, but given only two streams touch the key list, a cross-reference checkpoint on day 1 + peer review on each PR is sufficient and avoids a third document to keep in sync. If a third consumer emerges (e.g. Stream A's `money_formatter` ever needs a currency-name ARB key), consider promoting the cross-reference into its own doc then.

### 10.2 Concrete handoff items this stream owes Stream B

| Item                                                                        | Location                              | Format           |
|-----------------------------------------------------------------------------|---------------------------------------|------------------|
| Canonical DB `l10n_key` spelling for every seeded category and account type | §5.4 and §5.5, "DB `l10n_key`" column | Dotted lowercase |
| Canonical ARB getter name (camelCase) for each                              | §5.4 and §5.5, "ARB key" column       | Dart identifier  |

Stream B owes this stream: the canonical seeded dotted `l10n_key` set. Icon/color indices themselves do not surface in ARBs.

### 10.3 Blocking dependency on Stream A

**None.** `money_formatter.dart` and `date_helpers.dart` do not produce or consume ARB keys. The `splashSinceDate` placeholder format (`yMMMMd`) is resolved by `intl` at render time; Stream A's date helper layers on top but does not change the ARB shape. Ship independently.

---

## 11. Downstream consumers

| Consumer                                                             | Depends on this stream for                                                                                                                                                                                                                                   | Lands in                |
|----------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------|
| **M3 Seed routine** (`user_preferences_repository.dart` seed module) | Dotted `l10n_key` values for every seeded category + account type (§5.4, §5.5)                                                                                                                                                                               | M3 Stream C             |
| **M3 Repository tests**                                              | Dotted keys used in assertions when seed-idempotency tests verify `SELECT COUNT(*) WHERE l10n_key = 'category.food'`                                                                                                                                         | M3 Stream A             |
| **M4 App shell** (`app/app.dart`, `app/bootstrap.dart`)              | `lightTheme`, `darkTheme` imported into `MaterialApp.theme` / `.darkTheme`; theme provider wiring (shell owns the provider; this stream owns the constants)                                                                                                  | M4                      |
| **M4 Smoke widget test**                                             | `MaterialApp` builds with `AppLocalizations.delegate` + `lightTheme`; the smoke test becomes the template M5 slice tests extend                                                                                                                              | M4                      |
| **M5 Splash**                                                        | `splashEnter`, `splashSinceDate(date)`, `splashDayCountLabel`; Settings-for-splash labels rendered on Settings screen when splash is toggled                                                                                                                 | M5 Splash + M5 Settings |
| **M5 Home**                                                          | `navHome`, `homeEmptyTitle`, `homeEmptyCta`, `homeFabLabel`, `homeSummaryTodayExpense`, `homeSummaryTodayIncome`, `homeSummaryMonthNet`, `commonUndo`, `commonDelete`, `errorSnackbarGeneric`                                                                | M5 Home                 |
| **M5 Transactions (Add/Edit)**                                       | `transactionTypeExpense`, `transactionTypeIncome`, `commonSave`, `commonCancel`, `commonDiscard`, `commonEdit`, `errorSnackbarGeneric`                                                                                                                       | M5 Transactions         |
| **M5 Categories**                                                    | `commonAdd`, `commonEdit`, `commonArchive`, `commonDelete`; every `categoryFoo…` getter for rendering seeded rows                                                                                                                                            | M5 Categories           |
| **M5 Accounts**                                                      | `commonAdd`, `commonEdit`, `commonArchive`, `commonDelete`, `accountTypeCash`, `accountTypeInvestment`                                                                                                                                                       | M5 Accounts             |
| **M5 Settings**                                                      | `navSettings`, `settingsSplashSection`, `settingsSplashEnabled`, `settingsSplashStartDate`, `settingsSplashDisplayText`, `settingsSplashButtonLabel`, plus slice-local Theme-toggle / Language / Default-currency labels (added in the Settings PR per §7.3) | M5 Settings             |

---

## 12. Change-control protocol (this stream)

1. **Key rename or addition** — touches all three locales (`en`, `zh_TW`, `zh_CN`) in the same PR. `app_zh.arb` stays at `{appTitle}` only. `arb_audit_test.dart` (Task 8.6) catches drift; the pre-merge checklist asserts the test passed locally.
2. **Theme token change** — updates §4.2 or §4.3 in this doc, the Dart file, and any `lightTheme`/`darkTheme`-dependent test. Seed color hex in code and in §4.1 must match byte-for-byte.
3. **Seed `l10n_key` rename** — forbidden after M3 merges first seed to main. Renaming a dotted key after rows exist orphans existing user data (PRD 493 identity rule: `l10n_key` is the stable handle). If absolutely required, it ships as a schema-version bump with a data transform, not as an ARB-level refactor.
4. **Adding a new seeded category/account type** — requires a new row in PRD *Default Categories* / *Default Account Types*, then this stream adds three ARB entries plus a Stream B tuple, then M3 seed picks up the row. PRD change comes first; otherwise the ARB and seed drift from the spec.

---

## 13. Risk register

1. **Translator drift on Group S.** Non-native-speaker-written Chinese copy in §6 gets nitpicked later. Mitigation: §8.5 explicitly requests reviewer sign-off, and `errorSnackbarGeneric` plus CTAs are the highest-visibility strings — those are listed first in §6.1 so reviewers read them first.
2. **`app_zh.arb` accidentally deleted during cleanup.** CLAUDE.md warns; `arb_audit_test.dart` Task 8.6 assertion 3 is the automated guard.
3. **Seed `l10n_key` drift (`category.threeC` vs variants).** Lowercase-with-camel-tail is enforced in §5.4 by construction; `category.threeC` is the canonical key shared with Stream B and M3 seed.
4. **Codegen cache staleness.** After any ARB edit, running `flutter test` without first running `flutter pub get` uses the previous generated class. Every task's "Codegen" step runs `flutter pub get` first, which is why §8.8 lists the full command sequence.
5. **Theme accent drift via a `ThemeExtension` snuck in per-feature.** Out-of-scope here; if an M5 slice ships an extension, review asks "why not a shared key?" and the answer is documented — no silent forks.
6. **ICU placeholder format mismatch.** `{date}` with `format: yMMMMd` in EN must match both Chinese ARBs exactly; a difference emits a different method signature per locale and breaks `AppLocalizations` at compile time. Task 8.4's red test exercises this.

---

## 14. Self-review

- **(a)** Every seeded category from PRD 459–491 and every seeded account type from PRD 497–500 has an entry in each of `app_en.arb`, `app_zh_TW.arb`, `app_zh_CN.arb`. §5.4 + §5.5 list 20 rows (18 category + 2 account-type); §6.3 + §6.4 list the matching 20 in both Chinese locales. `arb_audit_test.dart` (Task 8.6) fails CI if any required pair is missing.
- **(b)** Base `app_zh.arb` preserved. §2.2 quotes current contents; §7.2 confirms post-plan contents are still `{"@@locale":"zh","appTitle":"Ledgerly"}`. CLAUDE.md pin cited verbatim.
- **(c)** No placeholders. Every EN string is final copy; every zh_TW/zh_CN value is a concrete translation in §6 (not `TODO` strings). Task 8.5 notes an explicit reviewer sign-off path if the authoring dev does not speak Chinese, but the table itself does not contain placeholders.
- **(d)** Theme choices are concrete. Seed color is `Color(0xFF006C35)` (Green 40) with rationale in §4.1; ColorScheme invocations are spelled out in §4.2; ThemeData knob allowlist is enumerated in §4.3. No "TBD", no "pick a color later".

Additional checks:
- PRD line ranges cited on every decision — §2, §4, §5, §7 all cite specific PRD lines.
- Three-column tables for ARB inventory — §5.2 / §5.3 / §5.4 / §5.5 use `key | usage | EN`, §6.1 / §6.2 / §6.3 / §6.4 use `key | zh_TW | zh_CN`.
- Theme-decision section — §4 covers seed, rationale, invocations, knobs.
- TDD tasks per writing-plans skill — §8 has seven red/green tasks, each with codegen + commit instructions.
- `flutter pub get` / codegen command reference after ARB edits — §8.8 plus per-task "Codegen" step.
- Seed-contract cross-reference section linking Stream B — §10.
- Exit criteria mapped to implementation-plan.md §5 M2 — §9.
- Downstream-consumer section (M3 seed, M4 shell, M5 slices) — §11.

---

## Critical Files for Implementation

- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/l10n/app_en.arb`
- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/l10n/app_zh_TW.arb`
- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/l10n/app_zh_CN.arb`
- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/lib/core/theme/color_schemes.dart`
- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/lib/core/theme/app_theme.dart`
