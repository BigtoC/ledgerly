# Ledgerly

Local-first Flutter expense tracker. Android-first, iOS supported. No bank
sync, no sign-in, no cloud required for the MVP.

The authoritative spec is **[`PRD.md`](PRD.md)**. When this file and the
PRD disagree, the PRD wins. The milestone sequencing lives in
[`docs/plans/implementation-plan.md`](docs/plans/implementation-plan.md).

## Status

M5 complete — all six feature slices (Splash, Home, Transactions, Categories,
Accounts, Settings) plus Wave 4 integration are on `main`. M6 (integration
polish, a11y, release prep) is next.

## Prerequisites

- Flutter (stable channel), Dart SDK `^3.11.5`. `flutter --version` must run
  cleanly.
- For Android builds: JDK 17 + Android SDK.
- For iOS builds: Xcode 15+ and CocoaPods.

## First-time setup

The repository ships the Dart / Flutter source, tests, lints, and CI
workflows. It does **not** commit the generated native platform scaffolds
(`android/`, `ios/`, `macos/`, …) because those are machine-generated and
their noise obscures reviewable changes. Generate them once, locally:

```bash
flutter create \
  --org finance.mantra \
  --project-name ledgerly \
  --platforms=android,ios \
  .
```

`flutter create` merges into the existing repo; keep all files it touches
that live under `android/` and `ios/` and discard any changes it proposes
to files this repo already owns (`pubspec.yaml`, `analysis_options.yaml`,
`lib/`, `test/`). When prompted or noticed, regenerate the native splash:

```bash
dart run flutter_native_splash:create
```

Then:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

You should see a placeholder screen with the text "Ledgerly".

## Common commands

```bash
flutter pub get                                     # resolve packages
flutter run                                         # device/emulator
flutter analyze                                     # custom_lint + riverpod_lint
dart run import_lint                                # enforce layer boundaries
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs
dart run drift_dev schema dump \
  lib/data/database/app_database.dart drift_schemas/
flutter test                                        # all tests
flutter test test/widget/smoke_test.dart            # single file
flutter test --name 'M0 smoke'                      # single group
dart format .
```

Regenerate code whenever a `@freezed`, `@riverpod`, or Drift
`@DriftDatabase` / `@DataClassName` annotation changes — the build fails
loudly if generated files are stale.

## Project layout

```text
lib/
  app/        # bootstrap, router, MaterialApp, providers
  core/       # theme, utils (money_formatter, icon_registry, color_palette, date_helpers)
  data/       # database + tables, DAOs, services, repositories, Freezed models
  features/
    splash/         # animated sun splash with day-count display
    home/           # day-at-a-time transaction list with summary strip
    transactions/   # add/edit form with calculator keypad
    categories/     # category list + form sheet with icon/color pickers
    accounts/       # account list + form with currency/type pickers
    settings/       # language, theme, default currency/account, splash toggle
l10n/         # Source ARB files (app_en, app_zh, app_zh_CN, app_zh_TW)
test/
  unit/       # services / repositories / controllers / utils
  widget/     # widget + golden tests
  integration/
drift_schemas/ # Committed schema snapshots per schemaVersion (v1, v2)
assets/
  splash/     # Splash assets (sun-themed asset lands in M6)
```

MVP has no `lib/domain/`; that directory is Phase 2 only, for use-case
orchestration across repositories.

## Architecture guardrails

Enforced combinations of lint + review + tests keep the layers honest. See
PRD -> Architecture for the full table. Headlines:

- Only `data/repositories/*` write to Drift or `flutter_secure_storage`.
- Drift data classes stay inside repositories; they never escape into
  controllers or widgets.
- Controllers expose immutable Freezed state + typed commands. Widgets
  never call DAOs, never construct Drift `Insertable` rows, and never
  transform data inside `build()`.
- Money is stored as integer minor units end-to-end. `double` is only
  allowed inside `core/utils/money_formatter.dart`.

`analysis_options.yaml` wires `flutter_lints`, `custom_lint`,
`riverpod_lint`, and `import_lint`; CI fails any PR that violates the
layer-boundary rules.

## Contributing

PRs must be green on the CI workflow at `.github/workflows/ci.yml`
(analysis, lint, codegen, tests, Android debug build). iOS runs nightly
via `.github/workflows/ios-nightly.yml`.

## Reference:
- Color codes: https://m3.material.io/styles/color/static/baseline#c9263303-f4ef-4a33-ad57-7d91dc736b6b
