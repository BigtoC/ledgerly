# M5 Wave 1 — Splash Slice

**Source of truth:** [`PRD.md`](../../../../PRD.md) → *Splash Screen (MVP)*, *Routing Structure*, *Testing Strategy → Widget Tests*. Contracts inherited from [`wave-0-contracts-plan.md`](../wave-0-contracts-plan.md).

Splash owns the `/splash` route: a hnotes-style day counter with sun background, large center number, rainbow-gradient start date, customizable display text, and an "Enter" button that fades to Home.

Golden tests are mandatory per `implementation-plan.md` → *Testing Rollout* — the visual design is a product requirement, not a nice-to-have.

---

## 1. Goal

Replace the M4 placeholder at `lib/features/splash/splash_screen.dart` with the real hnotes-style day counter. The splash-gate redirect (`splash_enabled?`) is already handled by the router and `splash_redirect_provider` from M4 — this slice does **not** modify router behavior.

---

## 2. Inputs

| Dependency                          | Purpose                                                                                             | Import path                                   |
|-------------------------------------|-----------------------------------------------------------------------------------------------------|-----------------------------------------------|
| `userPreferencesRepositoryProvider` | Read `splash_start_date`, `splash_display_text`, `splash_button_label`; write `splash_start_date` during the launch-time date-pick path | `app/providers/repository_providers.dart`     |
| `splashGateSnapshotProvider`        | First-frame hydrated snapshot of splash prefs from bootstrap                                        | `app/providers/splash_redirect_provider.dart` |
| `splashStartDateProvider`           | Reactive watch on `splash_start_date`                                                               | `app/providers/splash_redirect_provider.dart` |
| `date_helpers.dart`                 | `daysBetween(startDate, now)` (implemented in M2)                                                   | `core/utils/date_helpers.dart`                |
| `AppLocalizations`                  | `splash*` keys (already reserved in M4)                                                             | `l10n/app_localizations.dart`                 |
| `intl`                              | Locale-aware date formatting for the rainbow gradient                                               | `package:intl/intl.dart`                      |

Splash is read-mostly. It renders configured splash state from preferences, but it also owns the launch-time "no start date yet" path from the PRD: if splash is enabled and `splash_start_date` is missing, Splash presents the inline start-date action and writes the chosen date before continuing to the day-counter state. Settings remains the ongoing editor for `splash_*` preferences after first run.

**Date-picker bounds (both the launch-time prompt and any subsequent Settings edit):** `firstDate` is the earliest date the platform date picker will accept — use `DateTime(1900)` as the conventional lower bound. **No `lastDate` clamp** — future dates are allowed so users can run Splash as a countdown (negative day counts) and customize their splash text accordingly. The controller must **not** clamp negative day counts to zero.

---

## 3. Deliverables

### 3.1 Files (under `lib/features/splash/`)

- `splash_screen.dart` — replaces the M4 placeholder.
- `splash_controller.dart` — `@riverpod class SplashController extends _$SplashController`. Computes the state from prefs + `DateTime.now()`. Command surface is minimal: launch-time `setStartDate(DateTime)` for the PRD cold-start date-picker path. (The Enter button remains pure navigation.)
- `splash_state.dart` — Freezed sealed union (see §4).
- `widgets/splash_sun_background.dart` — background image + gradient tint.
- `widgets/splash_day_count.dart` — large centered count (`~90pt`, white).
- `widgets/splash_rainbow_gradient_text.dart` — rainbow `ShaderMask` over the formatted start date.
- `widgets/splash_enter_button.dart` — bottom button; calls `context.go('/home')`.

### 3.2 Assets

- `assets/splash/sun_background.png` — primary background image. Source and licensing documented in `assets/splash/README.md` (must be MIT-compatible or original).
- `2.0x/` / `3.0x/` asset variants per Flutter asset conventions.
- `pubspec.yaml` `flutter.assets:` entry added for `assets/splash/`.

Asset regeneration for native-splash (pre-Flutter static screen) stays **out of scope** — handled in M6 per `implementation-plan.md` → M6.

### 3.3 ARB keys

All required keys already exist in M4 (`splashEnter`, `splashSinceDate`, `splashDayCountLabel`). Audit for anything missing during implementation; add under `splash*` prefix only. Do not delete or rename existing keys.

### 3.4 Tests

- `test/unit/controllers/splash_controller_test.dart` — day-count math (edge cases: start date = today → 0 days; start date in the future → negative day count surfaced as-is (countdown use case, **not** clamped); DST transition days — delegate to `date_helpers` tests, assert controller just calls the helper).
- `test/unit/utils/splash_template_substitution_test.dart` — `{days}` and `{date}` template variable replacement for custom display text.
- `test/widget/features/splash/splash_screen_golden_test.dart` — **golden tests, mandatory.** Three variants:
  - Default text ("Since {date}"), start date = 100 days ago, English locale.
  - Custom display text ("`{days}` days strong"), zh_TW locale.
  - Long custom text at 2× text scale (verify overall layout survives while the fixed-height day count clamps at 1.5×; PRD → *Layout Primitives* → *Constraint rule*).
- `test/widget/features/splash/splash_screen_test.dart` — Enter button triggers navigation; direct render with `startDate = null` shows the launch-time "Set start date" action; choosing a date transitions the widget into the day-counter state while app-level routing tests continue to own the route-level splash gate.

---

## 4. State machine

```dart
@freezed
sealed class SplashState with _$SplashState {
  const factory SplashState.loading() = SplashLoading;
  const factory SplashState.data({
    required DateTime startDate,
    required int dayCount,
    required String formattedDisplayText,  // {date} / {days} already substituted
    required String buttonLabel,
  }) = SplashData;
  const factory SplashState.error(Object error, StackTrace stack) = SplashError;
}
```

No top-level `Empty` variant. When `splash_enabled = true` and `splash_start_date = null`, Splash renders the launch-time start-date prompt inline on `/splash`; choosing a date writes the preference and rebuilds into `SplashData` on the same route.

**No `SplashNeedsStartDate` variant.** The launch-time date prompt is treated as a specialized render path around the same controller-backed state, not as a separate long-lived state machine branch.

---

## 5. Visual spec (per PRD → *Splash Screen → Visual Design*)

Layering (bottom → top):
1. `splash_sun_background` — full-viewport image with a slight gradient tint to preserve text contrast in both light and dark themes. (The screen's palette is fixed per PRD — does **not** follow the active `ColorScheme`.)
2. Center content:
   - Huge day count — white, ~90pt, bold, explicit `TextScaler` clamp at 1.5× text scale (PRD → *Accessibility*).
   - Secondary label ("days" / localized via `splashDayCountLabel`) right below.
   - Rainbow-gradient text — displayed below the day count, showing the formatted start date using `intl.DateFormat.yMMMMd(locale)`. `ShaderMask` with a horizontal rainbow gradient (red → orange → yellow → green → blue → indigo → violet). Meets WCAG AA by rendering a solid fallback stroke behind the gradient or by ensuring gradient colors have sufficient luminance contrast with the background — verified with a contrast-check widget test at 2× scale.
3. Custom display text (if set) — below the gradient, sans-serif, wrapped.
4. Enter button — bottom center, filled button, label from prefs or default (`splashEnter`).

Template variable substitution for the display text (both default and custom):
- `{date}` → `intl.DateFormat.yMMMMd(Localizations.localeOf(context)).format(startDate)`
- `{days}` → `dayCount.toString()`

Substitution happens in the **controller**, not the widget — per PRD → *Controller Contract*, no `DateFormat` in `build()`.

---

## 6. Fade transition to Home

Already wired in M4 router via a `CustomTransitionPage` per PRD → *Routing Structure* ("Splash → Home transition uses a fade"). The Enter button calls `context.go('/home')`. This slice does not redefine the transition.

---

## 7. Accessibility

- Day count and secondary label each wrapped in `Semantics(label: ...)` so screen readers announce "X days since {date}".
- Enter button has an explicit `Semantics(button: true, label: buttonLabel)`.
- Text scaling: day count clamps at 1.5× per PRD → *Layout Primitives → Constraint rule*; display text reflows via `Wrap` / `Text` without truncation.
- Rainbow gradient must meet WCAG AA contrast — include a contrast smoke test.

---

## 8. Cross-slice contract adherence (Wave 0)

- §2.3 — **Settings owns ongoing splash preference editing** (`splash_enabled`, `splash_start_date`, `splash_display_text`, `splash_button_label`) from `/settings`, but Splash still owns the PRD-required launch-time start-date capture when splash is enabled and no start date exists yet.
- §2.4 — Do not edit `router.dart`, `splash_redirect_provider.dart`, or `user_preferences_repository.dart`. Read-only consumption of existing providers.
- §2.5 — Widgets under `lib/features/splash/widgets/`. No `core/widgets/` promotion.

**Coordination note:** Splash and Settings are both in Wave 1 and run in parallel. The launch-time start-date action lives on Splash; Settings provides the persistent editing surface afterward. Both write the same `splash_start_date` preference through `UserPreferencesRepository`; neither slice invents a second source of truth.

---

## 9. Out of scope (defer)

- Native pre-Flutter splash asset regeneration — M6.
- Persistent splash configuration UI from Settings (display text, button label, enabled toggle, and post-setup start-date editing) — **Settings slice** (Wave 1, parallel).
- Animated day counter (count-up) — not in MVP.
- Theme-aware splash coloring — PRD fixes the visual to the hnotes aesthetic regardless of theme.

---

## 10. Exit criteria

- `splash_screen.dart` renders the launch-time start-date prompt when `splash_start_date` is missing, and renders `Loading`, `Data`, and `Error` variants once configured.
- Day count math is correct for (a) today, (b) 100 days ago, (c) future start date (clamped to 0).
- Default and custom display text render correctly with `{date}` / `{days}` substitution.
- Enter button navigates to `/home` via the existing fade transition.
- Golden tests pass on the three variants from §3.4. Goldens checked in under `test/widget/features/splash/goldens/`.
- 2× text-scale test passes with the day count clamped to 1.5× (no overflow).
- WCAG AA contrast test passes on the rainbow gradient.
- `flutter analyze` clean; `flutter test` green.

---

## 11. Sequencing

Single agent, single PR:

1. Source + commit the sun background asset; update `pubspec.yaml` `flutter.assets:`.
2. Implement `splash_state.dart` + `splash_controller.dart` (including `{days}` / `{date}` substitution).
3. Implement `widgets/splash_sun_background.dart`, `splash_day_count.dart`, `splash_rainbow_gradient_text.dart`, `splash_enter_button.dart`.
4. Assemble `splash_screen.dart`.
5. Write controller + template-substitution unit tests.
6. Write widget tests (including golden tests with initial capture via `flutter test --update-goldens`).
7. Run `dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test` until green.
8. Open PR titled `feat(m5): splash slice`.

---

## 12. Risks

1. **Golden test flakiness across platforms.** Goldens are notoriously sensitive to font rendering. Run `flutter test --update-goldens` on the CI runner image (not locally) for the canonical artifacts; document the update command in the slice README.
2. **Rainbow contrast failure.** If the gradient colors at certain background tints fall below WCAG AA, add an outline/stroke behind the text or restrict the gradient's darker end. Contrast smoke test catches this pre-merge.
3. **Template substitution bugs.** `{days}` and `{date}` placeholders must be substituted verbatim, case-sensitive. User-entered custom text is untrusted — test that `{daysx}` is NOT substituted, `{DAYS}` is NOT substituted, escaped `\\{days\\}` renders literally (if we support escaping; skip for MVP).
4. **Asset licensing.** Sun background image must be MIT-compatible or original. `assets/splash/README.md` documents the source.
5. **Deprecated 1.5× scale clamping APIs.** Flutter 3.41 deprecates `textScaleFactor` in favor of `TextScaler`. Use `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5)`.
6. **Splash shown on every hot reload during development.** Router redirects work on cold start; dev-loop testing of Home should bypass splash via a manual `/home` deep link or by toggling `splash_enabled = false` in dev overrides — document the workaround in the slice PR description.
