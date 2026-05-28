# Dependency Pins

> Authoritative source: [`PRD.md` → *Dependencies*](../../PRD.md#dependencies) and the live `pubspec.yaml`.

Tested versions live in `pubspec.yaml`. Two non-obvious pins to preserve when bumping.

## `import_lint: ^0.1.6`

The 2.x line pulls `analyzer ^12.1.0` → `meta ^1.18.0`, but Flutter 3.41.7 pins `meta 1.17.0`. The 0.9.x–1.0.x band needs `analyzer ^5.2.0`, which conflicts with `freezed >=2.5.3`. **Only `^0.1.6` resolves under the current SDK.** Revisit when Flutter ships `meta 1.18+`.

### Config-file quirk

`import_lint 0.1.6` reads rules from `import_analysis_options.yaml` at the **repo root** and uses a regex schema (`search_file_path_reg_exp`, `not_allow_import_reg_exps`).

- An `import_lint:` block inside `analysis_options.yaml` is silently ignored.
- The glob-based `target_file_path` / `not_allow_imports` keys belong to the 2.x line — do **not** port them back.

Enforcement under the 0.1.6 pin is best-effort, so reviewer discipline matters more than the linter for layer-boundary rules — see [`layers.md`](./layers.md).

## Chinese ARBs require a base `app_zh.arb`

`flutter_localizations` fails codegen with `Arb file for a fallback, zh, does not exist` when only `app_zh_CN.arb` / `app_zh_TW.arb` are present.

**Keep `app_zh.arb` in `l10n/`** even if it only contains `appTitle` — removing it breaks `flutter pub get`. Bare `zh` resolves to English at runtime; the fallback exists only so codegen succeeds.

## Build-runner consumers

Code generation is required whenever any of these annotations changes — the build will fail loudly if generated files are stale:

- `@freezed` → `freezed` / `freezed_annotation`
- `@riverpod` → `riverpod_generator`
- `@DriftDatabase` / `@DataClassName` → `drift_dev`

Run `dart run build_runner build --delete-conflicting-outputs` (or the `watch` variant) after touching any of them.
