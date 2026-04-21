# M2 — Stream B: Icon registry + MD3 color palette

**Owner:** Agent B (Core utilities, icon/color half)
**Milestone:** M2 — Core utilities (`docs/plans/implementation-plan.md` §5, M2)
**Authoritative PRD ranges:** [`PRD.md`](../../../PRD.md)
- *Default Categories → Color Source (MD3 Baseline)*: lines **453–457**
- *Expense Categories* table: lines **459–477** (intentional color reuse noted at **477**)
- *Income Categories* table: lines **479–491**
- *Default Account Types*: lines **495–506**
- `categories` schema (`icon TEXT NOT NULL`, `color INTEGER NOT NULL`): lines **299–319**
- `account_types` schema: lines **321–339**
- *Icon & Color Registry*: lines **816–823**

**Sibling plans:**
- Stream A — `money_formatter` + `date_helpers` (no dependency on this stream).
- Stream C — Theme + ARBs. Reads the seed contract table below to wire `l10n_key` → localized display names for seeded categories / account types.
- M3 seed routine — reads the seed contract table below for every seeded `categories` and `account_types` row's `(icon, color)` tuple.

**Upstream dependencies:**
- M1 Stream B Freezed models (`data/models/category.dart`, `data/models/account_type.dart`) **must be merged** before Stream B starts. Stream B's seed contract depends on those types being final — a rename to `Category.icon` / `Category.color` / `AccountType.icon` / `AccountType.color` after this stream ships is a rebase bill across M3 seed code.
- `pubspec.yaml` already pins `material_symbols_icons: ^4.2803.0` (M0). Stream B does **not** edit `pubspec.yaml`.

**Stack:** Flutter `>=3.41.6`, `material_symbols_icons: ^4.2803.0`, Dart `^3.11.5`. No code generation involved.

---

## 1. Goal (one paragraph)

Ship two tiny, append-only registries — `color_palette.dart` (ordered `List<Color>` of MD3 baseline hexes) and `icon_registry.dart` (`Map<String, IconData>` of `Symbols.*`) — plus their unit tests, so that M3's first-run seed can insert `categories` and `account_types` rows with stable integer palette indices and string icon keys, and every UI screen in M5 can render those rows by resolving the indirect references at render time. No DB row, export bundle, or future backup/restore ever carries a raw `IconData` or ARGB int — that is **guardrail G8** from `docs/plans/implementation-plan.md` §6 and is the entire reason this stream exists.

---

## 2. Architecture

```text
lib/core/utils/
  color_palette.dart        # ordered List<Color> (append-only) + colorForIndex(int)
  icon_registry.dart        # Map<String, IconData> + iconForKey(String)

test/unit/utils/
  color_palette_test.dart   # clamp, append-only golden, PRD-hex verification
  icon_registry_test.dart   # fallback to Symbols.category, seed-key coverage
```

**Resolver shape — both registries.** Data rows store indirect references:

- `Category.icon: String`, `AccountType.icon: String` → `iconForKey(String)` → `IconData`.
- `Category.color: int`, `AccountType.color: int` → `colorForIndex(int)` → `Color`.

Resolution happens **at render time**, never in the DB layer. Widgets call `iconForKey(category.icon)` and `colorForIndex(category.color)` at the UI seam. M3 seed code reads the seed contract in §4 and writes the palette indices / icon keys directly into `categories.icon` / `categories.color` / `account_types.icon` / `account_types.color`.

**Stream B does not depend on Riverpod, Drift, or Freezed.** Both files are plain Dart with no `@generated` output, no `part 'X.g.dart'`. This keeps them importable by anything, testable without a `ProviderContainer`, and safe to load during `bootstrap.dart`'s synchronous phase if ever needed.

---

## 3. Tech Stack — exact imports

`color_palette.dart` imports:

```dart
import 'package:flutter/material.dart' show Color;
```

`icon_registry.dart` imports:

```dart
import 'package:flutter/widgets.dart' show IconData;
import 'package:material_symbols_icons/symbols.dart';
```

No other production imports. Tests additionally import `package:flutter_test/flutter_test.dart`.

---

## 4. Seed contract (the table M3 reads)

This section is the frozen contract. **Until this table is final, M3 cannot start.** Stream C reads the `l10n_key` column (left-most) to populate ARBs; M3 seed code reads the `icon key` and `palette index` columns.

### 4.1 Palette order (the source of truth for indices)

The MD3 baseline colors named by PRD 453–506 deduplicate into **11 unique entries**. They go into `color_palette.dart` in this order. **Do not reorder. Do not insert new indices in the middle. Append only.**

| Index | MD3 name           | Hex        | Consumed by (preview)                                            |
|-------|--------------------|------------|------------------------------------------------------------------|
| `0`   | Red 60             | `#B3251E`  | `category.food`                                                  |
| `1`   | Green 40           | `#006C35`  | `category.drinks`                                                |
| `2`   | Cyan 70            | `#00BBDF`  | `category.transportation`, `category.travel` (shared, PRD 477)   |
| `3`   | Purple 30          | `#5629A4`  | `category.shopping`, `category.education` (shared, PRD 477)      |
| `4`   | Green 80           | `#80DA88`  | `category.housing`, `category.personal` (shared, PRD 477)        |
| `5`   | Orange 70          | `#FF8D41`  | `category.entertainment`                                         |
| `6`   | Red 50             | `#DB372D`  | `category.medical`                                               |
| `7`   | Blue 30            | `#04409F`  | `category.threeC` (PRD "3C": phone/computer/gadgets)             |
| `8`   | Neutral Variant 50 | `#79747E`  | `category.miscellaneous`, `category.other` (shared, PRD 477)     |
| `9`   | Yellow 80          | `#FCBD00`  | All 5 income categories (PRD 479–491)                            |
| `10`  | Neutral Variant 70 | `#AEA9B4`  | `accountType.cash`, `accountType.investment` (PRD 499–500)       |

**Named constants.** To keep M3 seed code and code review readable, expose a named constant for each entry alongside the list. M3 writes `palette[CategoryPaletteIndex.food]` (or `CategoryPaletteIndex.food.index`), not a bare `0`. Constants are an **ergonomic alias** for indices — the list is still the source of truth, and constants can only ever be **appended**.

```dart
// Stable name → ordinal mapping. Only add new entries at the END.
abstract final class CategoryPaletteIndex {
  static const int red60           = 0;
  static const int green40         = 1;
  static const int cyan70          = 2;
  static const int purple30        = 3;
  static const int green80         = 4;
  static const int orange70        = 5;
  static const int red50           = 6;
  static const int blue30          = 7;
  static const int neutralVariant50 = 8;
  static const int yellow80        = 9;
  static const int neutralVariant70 = 10;
}
```

### 4.2 Icon keys (icon_registry.dart map)

Every seeded `categories.icon` and `account_types.icon` string key from the table below must exist as a map key in `icon_registry.dart`. Each icon is confirmed present in `material_symbols_icons ^4.2803.0` via the `Symbols.*` static accessor in the package's generated symbol bundle. Keys are **snake_case strings**, chosen to mirror the canonical `Symbols.*` Dart identifier, so the lookup stays trivially greppable across both code and DB.

### 4.3 Full seed contract table — categories

All PRD 459–491 entries. The `l10n_key` column is Stream C's input; the `icon key` and `palette index` columns are M3's input. One row per seeded category. Subcategories of seeded categories are **not seeded in M3** (PRD 493 says users can create custom subcategories); the subcategory column below is informational only, to help a reviewer sanity-check icon-key choice. If M3 later decides to seed the subcategories listed in PRD, each subcategory reuses its parent's icon key + palette index by default.

| `l10n_key`                   | Type      | Subcategories (PRD, informational) | Icon key           | Justification (1 line)                                        | Palette index (name → int)                        |
|------------------------------|-----------|------------------------------------|--------------------|---------------------------------------------------------------|---------------------------------------------------|
| `category.food`              | `expense` | Groceries, Restaurants             | `restaurant`       | Universal "food" glyph; covers grocery + dine-in use cases.   | `red60` → `0`                                     |
| `category.drinks`            | `expense` | Coffee, Alcohol, Beverages         | `local_cafe`       | Cup glyph generalizes across coffee / alcohol / beverage.     | `green40` → `1`                                   |
| `category.transportation`    | `expense` | Gas, Public Transit, Taxi, Parking | `directions_car`   | Car is the broadest "ground transport" glyph in Material.     | `cyan70` → `2`                                    |
| `category.shopping`          | `expense` | Clothing, Household                | `shopping_bag`     | Shopping bag reads as retail, not grocery.                    | `purple30` → `3`                                  |
| `category.housing`           | `expense` | Rent, Utilities, Maintenance       | `home`             | House silhouette = rent/utilities root.                       | `green80` → `4`                                   |
| `category.entertainment`     | `expense` | Movies, Games, Subscriptions       | `movie`            | Film reel covers movies + general entertainment.              | `orange70` → `5`                                  |
| `category.medical`           | `expense` | Doctor, Pharmacy, Insurance        | `medical_services` | Stethoscope/caduceus variant in MS reads as healthcare.       | `red50` → `6`                                     |
| `category.education`         | `expense` | Tuition, Books, Courses            | `school`           | Mortarboard = schooling / courses.                            | `purple30` → `3` (shared with shopping, PRD 477)  |
| `category.personal`          | `expense` | Haircut, Gym, Gifts                | `self_care`        | MS "self_care" glyph covers gym / haircut / self-spend.       | `green80` → `4` (shared with housing, PRD 477)    |
| `category.travel`            | `expense` | Flights, Hotels, Activities        | `flight`           | Plane glyph is the canonical travel/trip symbol.              | `cyan70` → `2` (shared with transport, PRD 477)   |
| `category.threeC`            | `expense` | Phone, Computer, Gadgets           | `devices`          | "Devices" = multi-device / gadget bucket — matches "3C".      | `blue30` → `7`                                    |
| `category.miscellaneous`     | `expense` | —                                  | `more_horiz`       | Three-dot "more" = miscellaneous / unsorted.                  | `neutralVariant50` → `8`                          |
| `category.other`             | `expense` | —                                  | `category`         | Generic "category" glyph = unnamed bucket.                    | `neutralVariant50` → `8` (shared w/ misc, PRD 477)|
| `category.income.salary`     | `income`  | —                                  | `payments`         | "Payments" glyph = incoming wage.                             | `yellow80` → `9`                                  |
| `category.income.freelance`  | `income`  | —                                  | `work`             | Briefcase = self-employment / contract work.                  | `yellow80` → `9`                                  |
| `category.income.investment` | `income`  | —                                  | `trending_up`      | Up-arrow chart = investment gains (also used by account type).| `yellow80` → `9`                                  |
| `category.income.gift`       | `income`  | —                                  | `redeem`           | Gift box glyph (MS `redeem`) = gift income.                   | `yellow80` → `9`                                  |
| `category.income.other`      | `income`  | —                                  | `savings`          | Piggy bank = misc income / savings deposit.                   | `yellow80` → `9`                                  |

### 4.4 Full seed contract table — account types

Both seeded rows, verbatim from PRD 497–500.

| `l10n_key`               | Icon key        | Justification (1 line)                             | Palette index (name → int)         |
|--------------------------|-----------------|----------------------------------------------------|------------------------------------|
| `accountType.cash`       | `wallet`        | Wallet glyph = physical cash holdings.             | `neutralVariant70` → `10`          |
| `accountType.investment` | `trending_up`   | Up-arrow chart = investment performance.           | `neutralVariant70` → `10`          |

Account types deliberately share a neutral tint — PRD 501–502 states "account types are visually distinguished by their **icon**, not by color."

### 4.5 Coverage checklist (review gate)

Before Stream B ships, a reviewer must confirm:

- [ ] Every expense category in PRD 459–477 appears as a row in §4.3 with a non-empty `icon key` + `palette index`.
- [ ] Every income category in PRD 479–491 appears as a row in §4.3.
- [ ] Every default account type in PRD 495–506 appears as a row in §4.4.
- [ ] Every `palette index` in §4.3 and §4.4 resolves to an entry in §4.1 (no dangling index names).
- [ ] Every `icon key` in §4.3 and §4.4 is a real `Symbols.*` identifier in `material_symbols_icons ^4.2803.0`.
- [ ] Shared-color rows match PRD 477's "intentional color reuse" list: Transportation+Travel on `cyan70`, Shopping+Education on `purple30`, Housing+Personal on `green80`, Other+Miscellaneous on `neutralVariant50`.

---

## 5. Current state of the two files (before this stream)

From M0, both files exist as documentation stubs. Quote them verbatim so the diff is obvious:

`lib/core/utils/icon_registry.dart`:

```dart
// TODO(M2): `Map<String, IconData>` mapping categories.icon string keys to
// `Symbols.*` from `material_symbols_icons`. Unknown keys fall back to
// `Symbols.category`. Keys are stable across Flutter / Material upgrades —
// never store raw IconData in the DB.
```

`lib/core/utils/color_palette.dart`:

```dart
// TODO(M2): Append-only ordered `List<Color>` of MD3-compatible category
// colours. `categories.color` is the index into this list.
//
// INDICES ARE PERMANENT. Reordering this list would retroactively remap
// every user's category colours. Additions must be appended at the end.
```

Both files have a `// TODO(M2):` header comment. Stream B replaces these stubs with real code while keeping the append-only rule prominently restated in the header docblock (§6).

---

## 6. File specs (the code Stream B will write)

### 6.1 `lib/core/utils/color_palette.dart`

```dart
// lib/core/utils/color_palette.dart
import 'package:flutter/material.dart' show Color;

/// -----------------------------------------------------------------------
/// APPEND-ONLY PALETTE — DO NOT REORDER. DO NOT REMOVE. DO NOT INSERT.
/// -----------------------------------------------------------------------
/// `categories.color` and `account_types.color` are integer indices into
/// `kCategoryColorPalette`. Reordering this list would retroactively remap
/// every user's category and account-type colours. Removing an entry would
/// orphan existing DB rows. Inserting at the middle does both.
///
/// Rules (enforced by code review, by the golden test in
/// `test/unit/utils/color_palette_test.dart`, and by implementation-plan.md
/// §9 risk #3):
///   1. New palette colours go at the END of the list. Always.
///   2. Existing indices never change meaning. A colour associated with
///      index 4 must stay at index 4 across every app version, forever.
///   3. Deprecating a colour means leaving it in place; new seeds must
///      pick a different index.
///   4. The corresponding `CategoryPaletteIndex` constant is added at the
///      same time as the list entry, with the same ordinal.
///
/// Source: Material Design 3 baseline palette
/// https://m3.material.io/styles/color/static/baseline
/// Cited by PRD.md → "Color Source — MD3 Baseline" (lines 453-457).
/// -----------------------------------------------------------------------

/// Ordered, append-only MD3 baseline palette. Treat as `const`.
const List<Color> kCategoryColorPalette = <Color>[
  Color(0xFFB3251E), // 0  Red 60
  Color(0xFF006C35), // 1  Green 40
  Color(0xFF00BBDF), // 2  Cyan 70
  Color(0xFF5629A4), // 3  Purple 30
  Color(0xFF80DA88), // 4  Green 80
  Color(0xFFFF8D41), // 5  Orange 70
  Color(0xFFDB372D), // 6  Red 50
  Color(0xFF04409F), // 7  Blue 30
  Color(0xFF79747E), // 8  Neutral Variant 50
  Color(0xFFFCBD00), // 9  Yellow 80
  Color(0xFFAEA9B4), // 10 Neutral Variant 70
];

/// Named indices for readability at the seed call site and in reviews.
/// M3 seed code SHOULD use these constants instead of bare ints so the
/// diff clearly communicates which colour is intended.
///
/// Append new names at the END and match the list above by ordinal.
abstract final class CategoryPaletteIndex {
  static const int red60            = 0;
  static const int green40          = 1;
  static const int cyan70           = 2;
  static const int purple30         = 3;
  static const int green80          = 4;
  static const int orange70         = 5;
  static const int red50            = 6;
  static const int blue30           = 7;
  static const int neutralVariant50 = 8;
  static const int yellow80         = 9;
  static const int neutralVariant70 = 10;
}

/// Resolves a palette index to a concrete [Color].
///
/// Out-of-range or negative indices clamp to [CategoryPaletteIndex.neutralVariant50]
/// (grey 50) as a safe, visually neutral fallback. An unknown index in the
/// wild usually means a corrupt restore or a forward-compat DB from a
/// future app version — we render *something* rather than throwing.
Color colorForIndex(int index) {
  if (index < 0 || index >= kCategoryColorPalette.length) {
    return kCategoryColorPalette[CategoryPaletteIndex.neutralVariant50];
  }
  return kCategoryColorPalette[index];
}
```

### 6.2 `lib/core/utils/icon_registry.dart`

```dart
// lib/core/utils/icon_registry.dart
import 'package:flutter/widgets.dart' show IconData;
import 'package:material_symbols_icons/symbols.dart';

/// -----------------------------------------------------------------------
/// ICON REGISTRY — stable string keys → Material Symbols IconData.
/// -----------------------------------------------------------------------
/// `categories.icon` and `account_types.icon` are string keys. The UI
/// resolves them to real `IconData` at render time via [iconForKey].
///
/// Why indirect:
///   * `IconData` is not stable across Flutter / Material updates; storing
///     raw codepoints would orphan rows on every package bump.
///   * Keys are portable across backup/restore and across future icon
///     font swaps.
///
/// Keys are snake_case strings that match the canonical `Symbols.*` Dart
/// identifier (e.g. the key `'restaurant'` resolves to `Symbols.restaurant`).
/// Unknown keys fall back to `Symbols.category` (PRD.md → Icon & Color
/// Registry, lines 816-823).
///
/// Adding a key:
///   1. Append to the map below. Never remove a key — if a seeded row
///      still references it, removing orphans the DB.
///   2. If the glyph is not in `material_symbols_icons ^4.2803.0`, bump
///      the package pin in `pubspec.yaml` in a separate PR.
/// -----------------------------------------------------------------------

/// Fallback icon returned by [iconForKey] on an unknown key.
const IconData kFallbackIcon = Symbols.category;

/// Stable-key -> IconData map. See header for the add/remove policy.
const Map<String, IconData> kIconRegistry = <String, IconData>{
  // Expense category roots (PRD 459-477).
  'restaurant':        Symbols.restaurant,
  'local_cafe':        Symbols.local_cafe,
  'directions_car':    Symbols.directions_car,
  'shopping_bag':      Symbols.shopping_bag,
  'home':              Symbols.home,
  'movie':             Symbols.movie,
  'medical_services':  Symbols.medical_services,
  'school':            Symbols.school,
  'self_care':         Symbols.self_care,
  'flight':            Symbols.flight,
  'devices':           Symbols.devices,
  'more_horiz':        Symbols.more_horiz,
  'category':          Symbols.category,

  // Income category roots (PRD 479-491).
  'payments':          Symbols.payments,
  'work':              Symbols.work,
  'trending_up':       Symbols.trending_up,
  'redeem':            Symbols.redeem,
  'savings':           Symbols.savings,

  // Default account types (PRD 497-500).
  'wallet':            Symbols.wallet,
  // 'trending_up' above is shared with the Investment account type.
};

/// Resolves an icon string key to an [IconData].
///
/// Unknown / `null`-string / empty keys fall back to [kFallbackIcon]
/// (`Symbols.category`). Never throws — a corrupted row in the DB should
/// still render.
IconData iconForKey(String? key) {
  if (key == null || key.isEmpty) return kFallbackIcon;
  return kIconRegistry[key] ?? kFallbackIcon;
}
```

---

## 7. TDD task decomposition

Tasks are bite-sized: each delivers a test + implementation in a single commit-sized unit. Tests are written **first**; implementation lands only after the test fails for the right reason. Order matters — later tasks depend on earlier ones being green.

### Task B-0 — Confirm upstream models are merged (5 min, no code)

**Gate, not a code change.** Verify on the M2 branch base:

- `lib/data/models/category.dart` declares `required String icon` and `required int color` on the `Category` factory.
- `lib/data/models/account_type.dart` declares `required String icon` and `required int color` on the `AccountType` factory.
- `pubspec.yaml` includes `material_symbols_icons: ^4.2803.0`.

If any of these are missing, **stop** and escalate — Stream B's seed contract depends on these shapes.

### Task B-1 — Palette: empty-list test passes against stub, then fleshed out

**Step 1 (red).** Create `test/unit/utils/color_palette_test.dart` with one test:

```dart
// test/unit/utils/color_palette_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/color_palette.dart';

void main() {
  group('kCategoryColorPalette', () {
    test('exposes at least one MD3 baseline colour', () {
      expect(kCategoryColorPalette, isNotEmpty);
    });
  });
}
```

The stub file (`// TODO(M2): ...`) doesn't even declare `kCategoryColorPalette`, so this fails to **compile** — that's the red we want.

**Step 2 (green).** Implement `color_palette.dart` per §6.1. Re-run; test passes.

### Task B-2 — Palette: PRD-hex round-trip (the core seed contract)

**Step 1 (red).** Extend the test file:

```dart
test('palette indices resolve to PRD-specified MD3 baseline hexes', () {
  // PRD.md 459-491, 497-500 — MD3 baseline hexes.
  expect(kCategoryColorPalette[CategoryPaletteIndex.red60].toARGB32(),
      0xFFB3251E);
  expect(kCategoryColorPalette[CategoryPaletteIndex.green40].toARGB32(),
      0xFF006C35);
  expect(kCategoryColorPalette[CategoryPaletteIndex.cyan70].toARGB32(),
      0xFF00BBDF);
  expect(kCategoryColorPalette[CategoryPaletteIndex.purple30].toARGB32(),
      0xFF5629A4);
  expect(kCategoryColorPalette[CategoryPaletteIndex.green80].toARGB32(),
      0xFF80DA88);
  expect(kCategoryColorPalette[CategoryPaletteIndex.orange70].toARGB32(),
      0xFFFF8D41);
  expect(kCategoryColorPalette[CategoryPaletteIndex.red50].toARGB32(),
      0xFFDB372D);
  expect(kCategoryColorPalette[CategoryPaletteIndex.blue30].toARGB32(),
      0xFF04409F);
  expect(kCategoryColorPalette[CategoryPaletteIndex.neutralVariant50]
          .toARGB32(),
      0xFF79747E);
  expect(kCategoryColorPalette[CategoryPaletteIndex.yellow80].toARGB32(),
      0xFFFCBD00);
  expect(kCategoryColorPalette[CategoryPaletteIndex.neutralVariant70]
          .toARGB32(),
      0xFFAEA9B4);
});
```

Note: `Color.toARGB32()` is Flutter 3.41+ API; if a reviewer flags compatibility, substitute `.value` (deprecated but still present) or `(r << 16) | (g << 8) | b | 0xFF000000`. The SDK target in `pubspec.yaml` (`flutter: ">=3.41.6"`) makes `.toARGB32()` safe.

**Step 2 (green).** Palette already implements these from Task B-1. Test should be green on re-run without further code change; if it isn't, the palette entry is wrong — fix it.

### Task B-3 — Palette: out-of-range clamps

**Step 1 (red).** Extend the test file:

```dart
group('colorForIndex', () {
  test('returns the entry at a valid index', () {
    expect(colorForIndex(0), kCategoryColorPalette[0]);
    expect(colorForIndex(kCategoryColorPalette.length - 1),
        kCategoryColorPalette.last);
  });

  test('out-of-range index clamps to Neutral Variant 50 (grey fallback)', () {
    final fallback =
        kCategoryColorPalette[CategoryPaletteIndex.neutralVariant50];
    expect(colorForIndex(-1), fallback);
    expect(colorForIndex(9999), fallback);
  });
});
```

**Step 2 (green).** `colorForIndex` from §6.1 already satisfies both. Re-run.

### Task B-4 — Palette: append-only golden test

**Goal:** prevent future PRs from reordering or shortening the palette. If a PR changes the hex at an existing index, this test fails loudly, forcing a conversation.

**Step 1 (red).** Add:

```dart
group('palette is append-only (GOLDEN — see color_palette.dart header)', () {
  // PRD.md 453-506 + this plan's §4.1. Editing this list is a CONTRACT
  // CHANGE — every user's seeded category/account-type colour is keyed
  // to a specific index. Only append new hexes; never reorder / remove.
  const goldenHexes = <int>[
    0xFFB3251E, // 0  Red 60
    0xFF006C35, // 1  Green 40
    0xFF00BBDF, // 2  Cyan 70
    0xFF5629A4, // 3  Purple 30
    0xFF80DA88, // 4  Green 80
    0xFFFF8D41, // 5  Orange 70
    0xFFDB372D, // 6  Red 50
    0xFF04409F, // 7  Blue 30
    0xFF79747E, // 8  Neutral Variant 50
    0xFFFCBD00, // 9  Yellow 80
    0xFFAEA9B4, // 10 Neutral Variant 70
  ];

  test('first N indices match the frozen golden list', () {
    expect(kCategoryColorPalette.length, greaterThanOrEqualTo(goldenHexes.length),
        reason:
            'Palette shrunk — an existing index was removed. This breaks '
            'every user DB referencing that index.');
    for (var i = 0; i < goldenHexes.length; i++) {
      expect(kCategoryColorPalette[i].toARGB32(), goldenHexes[i],
          reason:
              'Palette index $i changed hex. Palette is APPEND-ONLY; new '
              'colours must go at the END. See color_palette.dart header.');
    }
  });
});
```

**Step 2 (green).** Already green against §6.1. Failing this test in the future is the exact signal we want.

### Task B-5 — Icon registry: fallback path

**Step 1 (red).** Create `test/unit/utils/icon_registry_test.dart`:

```dart
// test/unit/utils/icon_registry_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/icon_registry.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  group('iconForKey fallback', () {
    test('unknown key returns Symbols.category (PRD 816-823 contract)', () {
      expect(iconForKey('this_key_does_not_exist'), Symbols.category);
    });
    test('null returns Symbols.category', () {
      expect(iconForKey(null), Symbols.category);
    });
    test('empty string returns Symbols.category', () {
      expect(iconForKey(''), Symbols.category);
    });
  });
}
```

Fails against the stub (`iconForKey` doesn't exist yet).

**Step 2 (green).** Implement §6.2. Re-run; green.

### Task B-6 — Icon registry: seed-contract coverage

**Step 1 (red).** Extend the test:

```dart
group('iconForKey resolves every key in the seed contract (§4.3, §4.4)', () {
  const seededKeys = <String>[
    // Expense categories.
    'restaurant', 'local_cafe', 'directions_car', 'shopping_bag', 'home',
    'movie', 'medical_services', 'school', 'self_care', 'flight', 'devices',
    'more_horiz', 'category',
    // Income categories.
    'payments', 'work', 'trending_up', 'redeem', 'savings',
    // Default account types.
    'wallet',
    // 'trending_up' shared — already covered above.
  ];

  for (final key in seededKeys) {
    test('"$key" resolves to a non-fallback IconData', () {
      final icon = iconForKey(key);
      // If the key is missing from kIconRegistry, iconForKey returns
      // Symbols.category (the fallback). That's only acceptable when the
      // key itself is 'category'.
      if (key != 'category') {
        expect(icon, isNot(Symbols.category),
            reason:
                'Seed contract key "$key" is missing from kIconRegistry — '
                'M3 seed would render the fallback glyph for this row.');
      } else {
        expect(icon, Symbols.category);
      }
    });
  }
});
```

**Step 2 (green).** §6.2 already registers all 19 keys. Re-run; green.

### Task B-7 — Icon registry: key identifier matches Symbols.\* name

A sanity test: the chosen string keys should look like their `Symbols.*` counterpart. Soft guarantee — useful for reviewers who want to grep.

```dart
test('registry keys are snake_case and present in the map', () {
  for (final entry in kIconRegistry.entries) {
    expect(entry.key, matches(RegExp(r'^[a-z][a-z0-9_]*$')),
        reason: 'Icon registry keys must be snake_case.');
    expect(entry.value, isA<IconData>());
  }
});
```

### Task B-8 — Review checklist (non-code)

Run §4.5 coverage checklist. Block merge if any item is unchecked.

### Task B-9 — Sample usage file (optional; skip if doc in §8 is enough)

If reviewers want a copy-paste reference, add `lib/core/utils/sample_usage_icons_colors.dart` with a handful of `iconForKey` + `colorForIndex` examples inside a commented-out `void main()`. Keep it tiny; never export from production. Otherwise the inline usage in §8 below carries the same weight.

---

## 8. Usage from downstream code (documentation, not implementation)

### 8.1 M3 seed (repositories)

```dart
// Illustrative — real code lives in M3's CategoryRepository.seed / AccountTypeRepository.seed.
import 'package:ledgerly/core/utils/color_palette.dart';

await categoriesDao.insertCategory(CategoriesCompanion.insert(
  l10nKey: const Value('category.food'),
  type: 'expense',
  icon: 'restaurant',                                 // icon key — resolved at render.
  color: CategoryPaletteIndex.red60,                  // palette index (= 0).
));

await categoriesDao.insertCategory(CategoriesCompanion.insert(
  l10nKey: const Value('category.travel'),
  type: 'expense',
  icon: 'flight',
  color: CategoryPaletteIndex.cyan70,                 // shared with transportation (PRD 477).
));

await accountTypesDao.insertAccountType(AccountTypesCompanion.insert(
  l10nKey: const Value('accountType.cash'),
  icon: 'wallet',
  color: CategoryPaletteIndex.neutralVariant70,
));
```

### 8.2 M5 rendering (widgets)

```dart
// Inside a widget render path.
import 'package:ledgerly/core/utils/color_palette.dart';
import 'package:ledgerly/core/utils/icon_registry.dart';

Widget buildCategoryTile(Category c) {
  return ListTile(
    leading: Icon(iconForKey(c.icon), color: colorForIndex(c.color)),
    title: Text(c.customName ?? localized(c.l10nKey)),
  );
}
```

Widgets **never** construct `Color` or `IconData` directly from DB fields; always go through the resolvers.

---

## 9. Exit criteria

Map 1-to-1 against `docs/plans/implementation-plan.md` §5 M2:

1. **Files land in their final paths.** `lib/core/utils/color_palette.dart` and `lib/core/utils/icon_registry.dart` implement §6 verbatim, replacing the M0 `TODO` stubs.
2. **Unit tests.** `test/unit/utils/color_palette_test.dart` and `test/unit/utils/icon_registry_test.dart` cover:
   (a) unknown icon key falls back to `Symbols.category` (Task B-5);
   (b) out-of-range / negative palette index returns the grey fallback (Task B-3);
   (c) every index promised to M3 seed in §4.3 / §4.4 resolves to the PRD-specified hex (Task B-2);
   (d) append-only golden test guards the first N palette entries against reorder (Task B-4);
   (e) every seed-contract icon key resolves to a non-fallback `IconData` (Task B-6).
3. **`flutter analyze` clean** on both files and both test files.
4. **`flutter test test/unit/utils/` passes.**
5. **Seed contract (§4) reviewed and signed off** by the reviewer covering M3 seed work — after this, §4 is frozen. Any subsequent change to an existing row requires a data migration.
6. **Append-only rule is visible in three places:** the code header comment in `color_palette.dart`, the plan's §6.1 + §10, and the golden test's failure message (§Task B-4).

Shared exit dependency: **Stream C** must read §4 to populate the `l10n_key` entries in the three ARBs (`app_en.arb`, `app_zh_TW.arb`, `app_zh_CN.arb`). Stream B does not write ARBs but commits to not changing its `l10n_key` column after Stream C has translated against it.

---

## 10. The append-only rule (prominent restatement)

A fourth place the rule lives, specifically for reviewers:

> **Any PR that changes an existing index in `kCategoryColorPalette` is a data migration, not a refactor.** Reviewer checklist for any diff that touches `color_palette.dart`:
>
> - Is every change an **append** at the end of the list?
> - Is the corresponding `CategoryPaletteIndex` constant also appended?
> - Is the `test/unit/utils/color_palette_test.dart` golden list extended (not reordered)?
>
> Any "no" answer is a migration requiring a `schemaVersion` bump and an `onUpgrade` step that rewrites every affected `categories.color` / `account_types.color` value. **That is expensive.** Prefer adding a new palette entry at the end and migrating a single seed row, if the product need justifies it at all.
>
> This rule mirrors `docs/plans/implementation-plan.md` §9 risk #3.

Same logic applies to `kIconRegistry`: removing a key orphans rows that reference it. Removals are not allowed in MVP. Renaming a key = add new + leave old in place + migrate affected rows. Never silent.

---

## 11. Downstream consumers

The following downstream work consumes Stream B's contract. Any change to §4 after Stream B ships impacts all of these:

- **M3 seed routine** (`data/repositories/category_repository.dart` + `account_type_repository.dart` + seed module). Reads §4.3 / §4.4 for every `(l10n_key, icon, color)` tuple it inserts.
- **M2 Stream C** (`lib/core/theme/app_theme.dart`, `l10n/app_{en,zh_TW,zh_CN}.arb`). Reads the `l10n_key` column in §4 to populate the ARBs with localized display names for every seeded category + account type. Stream C does **not** import `color_palette.dart` — theme colors come from the seed color scheme, not the category palette.
- **M5 Categories screen** (`features/categories/categories_screen.dart`). Renders each `Category.icon` via `iconForKey` in a leading `Icon`, tinted by `colorForIndex(category.color)`. Also the target of the category management flow (icon picker over `kIconRegistry.keys`, color picker over `kCategoryColorPalette`).
- **M5 Transactions** (`features/transactions/widgets/category_picker.dart`). `CategoryPicker` (frozen on day 1 of M5) renders a `SliverGrid` of category tiles — each tile is an `Icon` over a circular background filled with `colorForIndex(category.color)`.
- **M5 Accounts screen** (`features/accounts/accounts_screen.dart`). Each account-type tile renders `iconForKey(accountType.icon)` with `colorForIndex(accountType.color)` as the tile background. Both seeded types resolve to the same neutral tint by design (PRD 501–502).

---

## 12. Risks

### 12.1 Palette index reorder (implementation-plan.md §9 risk #3, restated)

**Impact:** catastrophic. Reordering `kCategoryColorPalette` retroactively remaps every user's category / account-type colour. Red-tagged "Food" becomes green overnight across every existing install.

**Mitigation — layered:**

1. **Header comment** in `color_palette.dart` (§6.1) — first line of defence for a developer opening the file.
2. **Golden test** (Task B-4) — CI fails loudly if the hex at an existing index changes. This is the enforceable half.
3. **Review checklist** (§10) — human half. Fails when the dev "updates" the test to match their change. Palette diffs should always be scrutinized by a reviewer who reads §10.
4. **Named `CategoryPaletteIndex` constants** — reorder attempts expose themselves because renaming a constant and renumbering it are two different diffs.

### 12.2 Icon key removal / rename

**Impact:** same shape as the palette reorder, but for strings. A rename without a data migration orphans DB rows.

**Mitigation:** rule in the registry header (§6.2); no automated test (a test that enumerates seed keys is already part of Task B-6 and would fail if a seed key is removed).

### 12.3 `material_symbols_icons` package bump

**Impact:** if a future Flutter / package bump renames or retires a `Symbols.*` identifier, Stream B's `const` map fails to compile — a *noisy* failure, which is what we want.

**Mitigation:** none needed pre-emptively. Resolve at the bump PR by either (a) aliasing the old name in `icon_registry.dart` comments + picking a new `Symbols.*` for the same key, or (b) bumping keys with a data migration. Package is pinned at `^4.2803.0` in `pubspec.yaml`; we confirmed every glyph in §4.3 / §4.4 exists in that version before writing this plan.

### 12.4 Accidental use of raw `IconData` / ARGB in new code

**Impact:** violates guardrail G8. Breaks the point of this stream.

**Mitigation:** reviewer grep for `Color(0x...)` and `IconData(...)` outside `lib/core/utils/color_palette.dart` / `lib/core/utils/icon_registry.dart` / theme files. If a future automated guardrail lands, it would be a custom-lint rule under `analysis_options.yaml`, but M2 is not the place to write it — defer to M6 polish if the pattern reappears.

---

## 13. Self-review (final gate before handing off)

Before Stream B lands on `main`, the author confirms each row below:

- [x] **Every seeded category in PRD 459–491 has an entry in §4.3.** (13 expense categories + 5 income categories = 18 rows.)
- [x] **Every seeded account type in PRD 495–506 has an entry in §4.4.** (Both seeded types: `accountType.cash`, `accountType.investment`.)
- [x] **Every `icon key` in §4.3 / §4.4 exists as a map key in §6.2's `kIconRegistry`.**
- [x] **Every `palette index` in §4.3 / §4.4 resolves to an entry in §4.1 / §6.1's `kCategoryColorPalette`.** (11 unique entries.)
- [x] **PRD 477's shared-colour list is preserved:** Transportation + Travel → index 2, Shopping + Education → index 3, Housing + Personal → index 4, Other + Miscellaneous → index 8.
- [x] **All 5 income categories share index 9 (Yellow 80).** Matches PRD 479–491.
- [x] **Both account types share index 10 (Neutral Variant 70).** Matches PRD 499–500 and PRD 501–502 rationale.
- [x] **Append-only rule is visible in:** code header (§6.1), plan §10, golden-test failure message (Task B-4), named-constants docblock (§6.1).
- [x] **No placeholder text** (`TODO`, `TBD`, `?`) remains in §4.3 / §4.4 / §6.1 / §6.2. Every cell is final.
- [x] **Zero dependency on Stream A or Stream C.** Stream B can merge standalone after M1.
- [x] **M1 dependency gate checked** (Task B-0): `Category.icon: String`, `Category.color: int`, `AccountType.icon: String`, `AccountType.color: int` are all required + non-nullable in the merged Freezed models.
- [x] **`pubspec.yaml` is not edited.** `material_symbols_icons ^4.2803.0` already present from M0.

---

*Stream B's contract with M3 is §4 (seed tuple per row) and §6 (resolver signatures). Stream B's contract with Stream C is §4's `l10n_key` column. Stream B's contract with M5 widgets is §6's `iconForKey` / `colorForIndex` signatures. Anything else is out of scope — push back to M3 or later.*

### Critical Files for Implementation
- /Users/bigtochan/Documents/dev/BigtoC/ledgerly/lib/core/utils/color_palette.dart
- /Users/bigtochan/Documents/dev/BigtoC/ledgerly/lib/core/utils/icon_registry.dart
- /Users/bigtochan/Documents/dev/BigtoC/ledgerly/test/unit/utils/color_palette_test.dart
- /Users/bigtochan/Documents/dev/BigtoC/ledgerly/test/unit/utils/icon_registry_test.dart
- /Users/bigtochan/Documents/dev/BigtoC/ledgerly/lib/data/models/category.dart
