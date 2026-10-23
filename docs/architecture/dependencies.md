# Dependency Pins

> Authoritative source: [`PRD.md` → *Dependencies*](../../PRD.md#dependencies) and the live `pubspec.yaml`.

Tested versions live in `pubspec.yaml`. Two non-obvious pins to preserve when bumping, plus the Android build toolchain.

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

## Android build toolchain

| Tool   | Version  | File                                               |
|--------|----------|----------------------------------------------------|
| Gradle | `9.7.0`  | `android/gradle/wrapper/gradle-wrapper.properties` |
| AGP    | `9.3.1`  | `android/settings.gradle.kts`                      |
| KGP    | `2.4.21` | `android/settings.gradle.kts` (`apply false`)      |
| JDK    | 17+      | CI: Temurin 21                                     |

### Why these versions

A bump has to pass all three checks:

1. **Kotlin's KGP table** ([kotlinlang.org → Configure a Gradle project](https://kotlinlang.org/docs/gradle-configure-project.html#apply-the-plugin)). KGP 2.4.20–2.4.21 covers Gradle 7.6.3–9.7.0 and AGP 8.5.2–9.3.1. KGP 2.4.0–2.4.10 stops at Gradle 9.5.0 and AGP 9.1.0.
2. **AGP's minimum Gradle** ([AGP release notes](https://developer.android.com/build/releases/about-agp)). AGP 9.3 needs Gradle 9.5.0, AGP 9.4 needs 9.6.0.
3. **Flutter 3.47.7.** The Gradle plugin's `DependencyVersionChecker` warns below Gradle 9.1.0, AGP 9.0.1 and KGP 2.3.20. `flutter analyze --suggestions` must show `[✓] Java/Gradle/KGP/Android Gradle Plugin`. Its tables (`packages/flutter_tools/lib/src/android/gradle_utils.dart`) stop at AGP 9.2 and KGP 2.4.0 and accept newer versions as unknown. So this check passes for any KGP above 2.4.0, and the Kotlin table is the real limit.

AGP 9.4.x with Gradle 9.8.x builds and passes Flutter's check, but it is outside the Kotlin table. Move to it when a KGP release lists it. Patch releases above the documented maxima (AGP 9.3.2/9.3.3, Gradle 9.7.1) also build. They fix R8/D8 bugs, but the Kotlin table does not list them yet.

### Built-in Kotlin and the KGP line

`android.builtInKotlin=true` lets AGP 9 compile Kotlin itself, so `app/build.gradle.kts` does not apply `kotlin-android`. AGP 9 rejects that plugin when Built-in Kotlin is on. Built-in Kotlin uses whichever kotlin-gradle-plugin is on the build classpath. AGP brings 2.2.10 and the Flutter Gradle Plugin 2.0.0, so the `id("org.jetbrains.kotlin.android") version "…" apply false` line in `settings.gradle.kts` is what sets the compiler version. `cd android && ./gradlew kgpVersion -q` prints it. Compiler options go in the top-level `kotlin { compilerOptions { … } }` block, because `android.kotlinOptions` does not exist under Built-in Kotlin. The Flutter 3.47.7 template and migrator write `android.builtInKotlin=false`. This project sets `true` on purpose.

### `android.newDsl=false`

AGP 9 defaults to the new DSL. The Flutter 3.47.7 Gradle plugin still casts the `android` extension to the legacy `AbstractAppExtension` and reads `applicationVariants`. With `newDsl=true` it fails to apply (`ApplicationExtensionImpl … cannot be cast to … AbstractAppExtension`). Tracked in [flutter/flutter#166550](https://github.com/flutter/flutter/issues/166550). AGP prints a deprecation warning for the flag and removes it in AGP 10. Flip it to `true` (or drop it) once a Flutter release migrates its plugin to the new variant API. Check that `cd android && ./gradlew help -Pandroid.newDsl=true` configures cleanly first.

Gradle 10 is blocked on Flutter for a similar reason. Under `--warning-mode all`, the Flutter Gradle Plugin triggers two Gradle 10 deprecations: "Using a Project object as a dependency notation" (reported at the `project.evaluationDependsOn(":app")` line in `android/build.gradle.kts`) and "Invocation of Task.project at execution time" in `compileFlutterBuild*`. Neither comes from this project's build scripts. Both stay warnings until Gradle 10.

### R8 defaults under AGP 9

Flutter's plugin enables `isMinifyEnabled` and `isShrinkResources` for release builds, so AGP 9's new R8 defaults apply:

- `android.r8.optimizedResourceShrinking=true` removes unused androidx resources. The split APKs' resource locale list drops to the default only. Flutter's UI strings come from `lib/l10n/`, not Android resources, so they are unaffected.
- `android.r8.strictFullModeForKeepRules=true` stops `-keep class X` from also keeping X's no-arg constructor. Plugin classes are still created directly from `GeneratedPluginRegistrant`, and the `jni`/`jni_flutter` rules use `{ *; }`, so nothing the app reaches at runtime is lost.

After a toolchain bump, compare `build/app/outputs/mapping/release/seeds.txt` and `configuration.txt` with the previous build.

## Build-runner consumers

Code generation is required whenever any of these annotations changes — the build will fail loudly if generated files are stale:

- `@freezed` → `freezed` / `freezed_annotation`
- `@riverpod` → `riverpod_generator`
- `@DriftDatabase` / `@DataClassName` → `drift_dev`

Run `dart run build_runner build --delete-conflicting-outputs` (or the `watch` variant) after touching any of them.
