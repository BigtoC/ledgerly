# M5 Wave 1 — Settings Slice

**Source of truth:** [`PRD.md`](../../../../PRD.md) → *MVP Screens → Settings*, *Splash Screen → Settings*, *Theme*, *Internationalization*. Contracts inherited from [`wave-0-contracts-plan.md`](../wave-0-contracts-plan.md).

Settings owns `/settings` (bottom-nav tab 3) and its sub-route `/settings/categories` navigation entry. It writes every user-preferences value that the other slices read reactively.

---

## 1. Goal

Replace the M4 placeholder at `lib/features/settings/settings_screen.dart` with a full settings screen: theme toggle, language selector, default account, default currency, splash configuration, and a "Manage Categories" navigation tile.

Settings is the **write-side** for every cross-slice preference. Splash, Home, Transactions, and Accounts read preferences via the same repository stream — there is no inter-controller messaging.

---

## 2. Inputs

| Dependency                          | Purpose                                                                                              | Import path                               |
|-------------------------------------|------------------------------------------------------------------------------------------------------|-------------------------------------------|
| `userPreferencesRepositoryProvider` | Read/write all preferences: `themeMode`, `locale`, `defaultCurrency`, `defaultAccountId`, `splash_*` | `app/providers/repository_providers.dart` |
| `accountRepositoryProvider`         | List non-archived accounts for the default-account picker                                            | `app/providers/repository_providers.dart` |
| `currencyRepositoryProvider`        | List currencies for the default-currency picker                                                      | `app/providers/repository_providers.dart` |
| `themeModeProvider` (M4)            | Reactive theme preference for the UI                                                                 | `app/providers/theme_provider.dart`       |
| `localePreferenceProvider` (M4)     | Reactive locale preference for the UI                                                                | `app/providers/locale_provider.dart`      |
| `AppLocalizations`                  | `settings*` keys (splash subsection already reserved) + any new UI keys                              | `l10n/app_localizations.dart`             |

Settings does **not** import from other feature slices. Navigation to `Categories` goes via `go_router`, not via a direct widget import.

---

## 3. Deliverables

### 3.1 Files (under `lib/features/settings/`)

- `settings_screen.dart` — replaces the M4 placeholder.
- `settings_controller.dart` — `@riverpod class SettingsController extends _$SettingsController`. Commands: `setThemeMode`, `setLocale`, `setDefaultCurrency`, `setDefaultAccountId`, `setSplashEnabled`, `setSplashStartDate`, `setSplashDisplayText`, `setSplashButtonLabel`.
- `settings_state.dart` — Freezed sealed union. `Data` carries all current pref values (see §4).
- `widgets/settings_section.dart` — reusable section header + body container.
- `widgets/theme_mode_selector.dart` — segmented control over `ThemeMode.{light,dark,system}`.
- `widgets/language_selector.dart` — list of supported locales (`en`, `zh_TW`, `zh_CN`).
- `widgets/default_account_tile.dart` — tap opens picker sheet (reuses `Accounts` slice's `CurrencyPickerSheet`? — no, Settings owns its own lightweight tile-based picker; see §5).
- `widgets/default_currency_tile.dart` — same shape, different data.
- `widgets/splash_settings_section.dart` — the splash subsection (enabled toggle, start date, display text, button label).
- `widgets/manage_categories_tile.dart` — `ListTile` that navigates via `context.go('/settings/categories')`.

### 3.2 ARB keys

Prefix: `settings*` (UI). Splash subsection keys already reserved in M4 (`settingsSplashSection`, `settingsSplashEnabled`, `settingsSplashStartDate`, `settingsSplashDisplayText`, `settingsSplashButtonLabel`).

Minimum new keys: `settingsSectionGeneral`, `settingsSectionAppearance`, `settingsSectionCategoriesTile`, `settingsThemeLabel`, `settingsThemeLight`, `settingsThemeDark`, `settingsThemeSystem`, `settingsLanguageLabel`, `settingsLanguageEnglish`, `settingsLanguageZhTw`, `settingsLanguageZhCn`, `settingsDefaultAccountLabel`, `settingsDefaultAccountEmpty`, `settingsDefaultCurrencyLabel`, `settingsManageCategories`. Discovered during implementation; all four ARBs updated in the same PR.

### 3.3 Tests

- `test/unit/controllers/settings_controller_test.dart` — each command writes through the repository; state re-emits on stream update; error surfaces when write fails.
- `test/widget/features/settings/settings_screen_test.dart` — all sections render; changing theme triggers repository write; changing locale does the same; default-account tile shows "Not set" if `defaultAccountId` is `null`; "Manage Categories" tile navigates to `/settings/categories` (mock `GoRouter`).
- `test/widget/features/settings/splash_settings_section_test.dart` — toggle hides/shows the start-date picker; first-run (no date set) surfaces the picker inline; display-text + button-label text fields persist on submit.

---

## 4. State machine

```dart
@freezed
sealed class SettingsState with _$SettingsState {
  const factory SettingsState.loading() = SettingsLoading;
  const factory SettingsState.data({
    required ThemeMode themeMode,
    required Locale? locale,          // null = follow system
    required String defaultCurrency,
    required int? defaultAccountId,   // null = none set (first run until user picks)
    required bool splashEnabled,
    required DateTime? splashStartDate,
    required String? splashDisplayText,  // null = use default l10n template
    required String? splashButtonLabel,  // null = use default l10n label
  }) = SettingsData;
  const factory SettingsState.error(Object error, StackTrace stack) = SettingsError;
}
```

No `Empty` variant. The bootstrap sequence guarantees user_preferences is populated on first render.

---

## 5. Sections

Rendered as a `CustomScrollView` with `SliverList` per section. Section headers use `settings_section.dart`.

| Section         | Widgets                                                                                               | Notes                                                                                                                                                                    |
|-----------------|-------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Appearance      | `theme_mode_selector`, `language_selector`                                                            | Theme writes via `setThemeMode`; locale via `setLocale`. UI rebuilds reactively from M4 providers.                                                                       |
| General         | `default_account_tile`, `default_currency_tile`                                                       | Default-account picker lists non-archived accounts from `accountRepository.watchAll()`. Default-currency picker lists `currencies` from `currencyRepository.watchAll()`. |
| Splash          | `splash_settings_section` (enabled toggle, conditional start-date picker, display text, button label) | Toggle off hides the start-date, display-text, and button-label rows. (PRD → *Splash Screen → Settings*)                                                                 |
| Data management | `manage_categories_tile`                                                                              | Navigates to `/settings/categories`. (Wallets / Ankr key tiles are Phase 2 — not in this slice.)                                                                         |

---

## 6. Splash settings subsection

Contract inherited from `splash-plan.md` §8: **Settings is the sole writer for `splash_*` preferences.** Splash slice (parallel in Wave 1) reads them.

- **Enabled** — `Switch`, default `true`. Writes `splash_enabled`.
- **Start date** — conditional on `enabled == true`. Tap opens a platform date picker (`showDatePicker`). Writes `splash_start_date`. If `null` and splash is enabled, the router redirects to Settings on cold start (M4 behavior) and the tile highlights with a leading warning icon.
- **Display text** — `TextField`. Placeholder shows the localized default (`splashSinceDate`). Writes `splash_display_text`. Hint text mentions the `{date}` and `{days}` template variables (PRD → *Splash Screen → Settings*).
- **Button label** — `TextField`. Placeholder shows `splashEnter`. Writes `splash_button_label`.

**Migration of the M4 inline "Set start date" button:** The M4 placeholder on the splash screen offers an inline "Set start date" button. That affordance is **moved here** in this Wave 1 PR. The Splash slice removes it in the same wave (confirmed with splash-plan.md §8).

---

## 7. Default-account picker

Tap opens a `ModalBottomSheet` listing non-archived accounts via `accountRepository.watchAll(includeArchived: false)`. Each row shows icon + name + account-type chip. Tapping a row calls `setDefaultAccountId(id)` and dismisses.

If no accounts exist (only possible if the user has archived every account — the seed guarantees one Cash account at first run), the sheet shows a "Create account" CTA that navigates to `/accounts/new`.

---

## 8. Default-currency picker

Tap opens a similar sheet listing currencies from `currencyRepository.watchAll()`. Grouped by fiat/token (tokens only in Phase 2 — MVP sheet shows fiat only; gating is `!currency.isToken`). Row = code + symbol + localized name via `name_l10n_key`.

Tapping writes `setDefaultCurrency(code)`.

---

## 9. Cross-slice contract adherence (Wave 0)

- §2.3 — Settings writes, others read. No cross-controller push. Accounts, Transactions, Splash, Home all subscribe to the same repository streams and react automatically.
- §2.3 — "Manage Categories" link is Settings' responsibility; Categories owns the screen. Do not duplicate the link elsewhere.
- §2.4 — Do not edit `router.dart`, repositories, or the schema. If a new preference key is needed, it's a schema concern (key is a TEXT column) and requires only a repository method addition — raise Platform RFC.
- §2.5 — Widgets under `lib/features/settings/widgets/`. Reuse of Accounts' `CurrencyPickerSheet` is **not** allowed in MVP (Wave 0 §2.5 — no cross-slice widget imports in MVP unless explicitly promoted).

---

## 10. Out of scope (defer)

- **Wallets management** (`/settings/wallets`) — Phase 2.
- **Ankr API key** (`/settings/ankr-key`) — Phase 2.
- **CSV export/import** — Phase 3.
- **Cloud backup & sync** — Phase 3.
- **App lock / passcode** — Future.
- Per-category default-currency overrides — not in PRD for MVP.

---

## 11. Exit criteria

- `settings_screen.dart` renders all sections; each control writes through the repository and re-renders reactively.
- Toggling the splash `enabled` switch hides/shows the start-date, display-text, and button-label rows.
- The M4 inline "Set start date" button is removed from `splash_screen.dart` (coordinated with Splash slice — both land in Wave 1).
- "Manage Categories" tile navigates to `/settings/categories`.
- Theme / locale changes rebuild the whole app live (via existing M4 providers).
- 2× text scale passes on the settings screen.
- `flutter analyze` clean; `flutter test` green, including §3.3 tests.

---

## 12. Sequencing

Single agent, single PR:

1. Implement `settings_state.dart` + `settings_controller.dart`, expose all commands.
2. Implement `widgets/settings_section.dart`, `theme_mode_selector.dart`, `language_selector.dart`.
3. Implement `widgets/default_account_tile.dart` + picker sheet, `default_currency_tile.dart` + picker sheet.
4. Implement `widgets/splash_settings_section.dart` — full splash subsection including conditional visibility.
5. Implement `widgets/manage_categories_tile.dart`.
6. Assemble `settings_screen.dart`.
7. Coordinate with Splash slice: remove the M4 inline "Set start date" button from `splash_screen.dart`. This edit lands in the Settings PR (not the Splash PR) to avoid merge ordering issues — Splash expects it gone by the time Splash PR opens. Alternative: land it in Splash PR; decide at slice kickoff.
8. Add ARB keys (§3.2) across all four ARB files.
9. Write controller + screen + splash-subsection widget tests.
10. Run `dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test`.
11. Open PR titled `feat(m5): settings slice`.

---

## 13. Risks

1. **Theme rebuild scope.** Changing `themeMode` must rebuild `MaterialApp`. Already wired in M4 via `themeModeProvider`; Settings only writes through the repository. Do **not** directly tweak `MaterialApp.theme` from inside Settings — the `write -→ read` loop handles it.
2. **Locale change flicker.** Same pattern: write to prefs, `localePreferenceProvider` re-emits, `MaterialApp.locale` updates. Test for: changing locale updates all currently-visible strings without manual navigation.
3. **Coordinating the splash button removal.** Splash and Settings are parallel in Wave 1. The "Set start date" button removal is logically Settings' concern (Settings takes over the responsibility) but physically lives in `splash_screen.dart`. Recommended: Settings PR does the removal; Splash PR assumes it's already gone. If Splash PR lands first, it leaves the placeholder button; Settings PR will clean up.
4. **Default-account picker with zero accounts.** Show "Create account" CTA, not a blank sheet.
5. **Default-currency picker with Phase 2 tokens visible.** Filter on `!currency.isToken` in MVP.
6. **Text-field persistence.** Free-text fields for display text / button label should debounce writes (e.g. 300ms) rather than write on every keystroke — otherwise the Drift stream churns. Controller commands accept the final value on focus-out or explicit submit.
7. **Unchecked locale assumption.** If `locale == null` (follow system), changing the OS language should propagate. Verified by a widget test that toggles system locale and asserts strings change.
