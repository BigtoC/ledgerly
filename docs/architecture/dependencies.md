# Dependency Pins

> Authoritative source: [`PRD.md` → *Dependencies*](../../PRD.md#dependencies) and the live `pubspec.yaml`.

Tested versions live in `pubspec.yaml`. Two non-obvious pins to preserve when bumping.

## `import_lint: ^0.1.6`

The 2.x line (newest: 2.0.0) pins `analyzer ^12.1.0`. The code-gen stack now needs analyzer 14: `freezed 4.0.3` requires `>=14`, and `riverpod_generator 4.0.9` and `drift_dev 2.35` require `>=13`. The 0.9.x–1.0.x band needs `analyzer ^5.2.0`, which conflicts with `freezed >=2.5.3`. **Only `^0.1.6` resolves under the current stack.** Revisit when an `import_lint` release supports analyzer 14.

### Config-file quirk

`import_lint 0.1.6` reads rules from `import_analysis_options.yaml` at the **repo root** and uses a regex schema (`search_file_path_reg_exp`, `not_allow_import_reg_exps`).

- An `import_lint:` block inside `analysis_options.yaml` is silently ignored.
- The glob-based `target` / `from` / `except` keys under an `import_lint:` block in `analysis_options.yaml` belong to the 1.x/2.x lines. Do **not** use them with 0.1.6.

### 0.1.6 does not enforce the rules

`dart run import_lint` runs in CI, but under the 0.1.6 pin it enforces nothing:

- It lists files with `Directory.current.list()`, which yields absolute paths, so the `^lib/...` `search_file_path_reg_exp` patterns never match.
- It calls `exit(0)` after printing its report, so CI would not fail even if a rule matched.

Adding `import 'package:ledgerly/data/database/app_database.dart';` to `lib/features/home/home_screen.dart` (a `widgets_forbid_data_internals` violation) still prints "No issues found!" and exits 0. Until a working check replaces it, reviewer discipline is what enforces layer-boundary rules — see [`layers.md`](./layers.md).

## Chinese ARBs require a base `app_zh.arb`

`flutter_localizations` fails codegen with `Arb file for a fallback, zh, does not exist` when only `app_zh_CN.arb` / `app_zh_TW.arb` are present.

**Keep `app_zh.arb` in `l10n/`** even if it only contains `appTitle` — removing it breaks `flutter pub get`. Bare `zh` resolves to English at runtime; the fallback exists only so codegen succeeds.

## Build-runner consumers

Code generation is required whenever any of these annotations changes — the build will fail loudly if generated files are stale:

- `@freezed` → `freezed` / `freezed_annotation`
- `@riverpod` → `riverpod_generator`
- `@DriftDatabase` / `@DataClassName` → `drift_dev`

Run `dart run build_runner build --delete-conflicting-outputs` (or the `watch` variant) after touching any of them.
