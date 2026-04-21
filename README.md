# Ledgerly

Local-first Flutter expense tracker. Android-first, iOS supported. No bank
sync, no sign-in, no cloud required for the MVP.

The authoritative spec is **[`PRD.md`](PRD.md)**. When this file and the
PRD disagree, the PRD wins. The milestone sequencing lives in
[`docs/plans/implementation-plan.md`](docs/plans/implementation-plan.md).

## Status

Pre-implementation: M0 (scaffold + toolchain) is landing. M1+ work begins
once this lands on `main`.

## Prerequisites

- Flutter (stable channel), Dart SDK `^3.6`. `flutter --version` must run
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
  app/        # bootstrap, router, MaterialApp
  core/       # theme, utils, l10n helpers
  data/       # database, DAOs, services, repositories, Freezed models
  features/   # splash, home, transactions, categories, accounts, settings
l10n/         # Source ARB files (en, zh_TW, zh_CN)
test/
  unit/       # services / repositories / controllers / utils
  widget/     # widget + golden tests
  integration/
drift_schemas/ # Committed schema snapshots per schemaVersion
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
