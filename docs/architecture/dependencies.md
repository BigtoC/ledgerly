# Dependency Pins

> Authoritative source: [`PRD.md` → *Dependencies*](../../PRD.md#dependencies) and the live `pubspec.yaml`.

Tested versions live in `pubspec.yaml`. This page covers the layer-boundary check that replaced `import_lint`, the base `app_zh.arb` requirement, and the Android build toolchain.

## Layer-boundary check

`test/unit/architecture/layer_boundaries_test.dart` enforces the PRD -> Layer Boundaries table. CI runs it as its own step (`flutter test test/unit/architecture/`) right after `flutter pub get`, and again in the full suite.

- **Rules** live in `import_analysis_options.yaml` at the repo root, the only file the test reads. `search_file_path_reg_exp` matches the repo-relative path of each `lib/**/*.dart` file (generated `*.g.dart` / `*.freezed.dart` excluded). `not_allow_import_reg_exps` matches every `import` and `export` URI in that file, after relative URIs are rewritten to `package:ledgerly/...`. `ignore_import_reg_exps` exempts URIs: `core_stays_pure` forbids all of `data/` and exempts only `data/models/`, so a new `data/` subdirectory is forbidden to `core/` by default. `part` / `part of` are skipped.
- **Feature coverage.** Every file under `lib/features/` matches at least one rule. `feature_providers_forbid_db_and_services` gives `*_providers.dart` the controller rule. `feature_files_forbid_data_internals` is a catch-all whose path regex uses negative lookahead to skip `*_controller` / `*_providers` / `*_state` / `*_screen.dart` and `widgets/`, and gives every other feature file the widget rule. A new feature file is therefore covered as soon as it exists; one that needs repositories must be a `*_controller.dart` or `*_providers.dart`. The name-based rules (screen, controller, providers, state) can overlap with the `widgets/` rule for a file under `widgets/`; each matching rule reports its own violation. The catch-all never overlaps.
- **Provider back doors.** Import paths cannot show what a file reaches through a provider, so the feature rules also forbid the files that build repositories, services and the database. Screens, `widgets/`, states and the catch-all forbid `app/providers/repository_providers.dart`; every feature rule forbids `app/providers/service_providers.dart`, `app/providers/app_database_provider.dart` and the platform and I/O plugins `package_info_plus`, `dio`, `file_picker`, `file_selector` and `path_provider`. A provider that widgets may read, such as `exchangeRatesProvider`, therefore lives in its own file under `app/providers/`. The `rules in import_analysis_options.yaml` group in the test pins these rules for one file of each kind, so loosening one fails a test even before a file in `lib/` breaks it.
- **Baseline.** Violations that predate the check are listed under `baseline:` in the same file. New violations fail, and so does a baseline entry that no longer occurs, so the list can only shrink. Fix the code and delete the entry; do not add entries for new code. If an entry shows that the rule, not the code, is wrong, fix the rule (and the PRD table it mirrors) and delete the entry. That is how `core_stays_pure` came to allow `data/models/`.
- **Dependencies.** The test uses `package:yaml`, a declared dev dependency, and no analyzer. It reads only the directive header of each file.

### Why not `import_lint`

`import_lint` was dropped. The 0.1.6 pin, the only line that resolved, enforced nothing: it matched the `^lib/...` rules against the absolute paths from `Directory.current.list()`, so no rule ever applied, and it always called `exit(0)`. The 2.x line (newest: 2.0.0) pins `analyzer ^12.1.0`, but `freezed 4.0.3` requires `>=14`, and `riverpod_generator 4.0.9` and `drift_dev 2.35` require `>=13`. The 0.9.x–1.0.x band needs `analyzer ^5.2.0`, which conflicts with `freezed >=2.5.3`. The rule key names in `import_analysis_options.yaml` are inherited from 0.1.6.

## Chinese ARBs require a base `app_zh.arb`

`flutter_localizations` fails codegen with `Arb file for a fallback, zh, does not exist` when only `app_zh_CN.arb` / `app_zh_TW.arb` are present.

**Keep `app_zh.arb` in `l10n/`** even if it only contains `appTitle` — removing it breaks `flutter pub get`. Bare `zh` resolves to English at runtime; the fallback exists only so codegen succeeds.

## Android build toolchain

| Tool   | Version  | File                                               |
|--------|----------|----------------------------------------------------|
| Gradle | `9.7.1`  | `android/gradle/wrapper/gradle-wrapper.properties` |
| AGP    | `9.3.3`  | `android/settings.gradle.kts`                      |
| KGP    | `2.4.21` | `android/settings.gradle.kts` (`apply false`)      |
| JDK    | 17+      | CI: Temurin 21                                     |

### Why these versions

A bump has to pass all three checks. The one exception is patch releases on the Kotlin table's newest minor lines (see [Patch releases above the Kotlin table](#patch-releases-above-the-kotlin-table)).

1. **Kotlin's KGP table** ([kotlinlang.org → Configure a Gradle project](https://kotlinlang.org/docs/gradle-configure-project.html#apply-the-plugin)). KGP 2.4.20–2.4.21 covers Gradle 7.6.3–9.7.0 and AGP 8.5.2–9.3.1. KGP 2.4.0–2.4.10 stops at Gradle 9.5.0 and AGP 9.1.0.
2. **AGP's minimum Gradle** ([AGP release notes](https://developer.android.com/build/releases/about-agp)). AGP 9.3 needs Gradle 9.5.0, AGP 9.4 needs 9.6.0.
3. **Flutter 3.47.7.** The Gradle plugin's `DependencyVersionChecker` warns below Gradle 9.1.0, AGP 9.0.1 and KGP 2.3.20. `flutter analyze --suggestions` must show `[✓] Java/Gradle/KGP/Android Gradle Plugin`. Its tables (`packages/flutter_tools/lib/src/android/gradle_utils.dart`) stop at AGP 9.2 and KGP 2.4.0 and accept newer versions as unknown. So this check passes for any KGP above 2.4.0, and the Kotlin table is the real limit.

AGP 9.4.x with Gradle 9.8.x builds and passes Flutter's check, but it is outside the Kotlin table. Move to it when a KGP release lists it.

#### Patch releases above the Kotlin table

AGP 9.3.3 and Gradle 9.7.1 are patch releases above the Kotlin table's maxima (9.3.1 and 9.7.0): two AGP patches and one Gradle patch. JetBrains does not list them as fully supported for KGP 2.4.21. The page says newer Gradle and AGP versions can be used, but "you might encounter deprecation warnings or some new features might not work." This is a deliberate choice: the patches stay on the same minor lines and fix bugs that affect release builds.

- **AGP 9.3.2:** lint no longer crashes on JDK 17 (`NoSuchMethodError: java.util.List.removeLast()`, [522845800](https://issuetracker.google.com/issues/522845800)).
- **AGP 9.3.3:** R8 builds are deterministic again, so identical input gives identical dex and mapping ([554586985](https://issuetracker.google.com/issues/554586985)). It fixes dex files that intermittently fail verification and crash the app on launch ([485558707](https://issuetracker.google.com/issues/485558707)). It also fixes an R8 outliner `VerifyError` ([551348855](https://issuetracker.google.com/issues/551348855)), a D8 debug-mode crash, duplicate R8 mappings, high R8 per-rule memory use, a ~38% slower `mergeProjectDexDebug`, and `optimization { enable = true }` not setting `isMinifyEnabled`.
- **Gradle 9.7.1:** fixes regressions from 9.7.0, among them `BaseExecSpec` streams, test-failure diff output, bundled antlr leaking onto the kapt classpath, and `ant.taskdef` classpath isolation.

Compared with 9.3.1 / 9.7.0 under JDK 21, the patches add no new warnings to `assembleDebug --warning-mode all`. In the signed split-per-ABI release APKs, `aapt2` badging and manifest trees are identical, every `.so` and `classes.dex` keeps its size, R8's `pg-map-id` and `mapping.txt` are the same, and `seeds.txt` has the same entries in a different order. The dex is semantically identical (`dexdump -a -d` matches); its bytes differ in the R8 version marker (9.3.16 → 9.3.28), the header checksum and the order of annotation items. `libdartjni.so` differs only in its build ID. `zipalign -c -P 16` and `apksigner verify` pass. If a KGP release lists 9.3.3 / 9.7.1 or later, this exception ends. Do not use it to justify moving to a new minor line.

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

## iOS build toolchain

| Item                  | Value                       | Set in                                                        |
|-----------------------|-----------------------------|---------------------------------------------------------------|
| Deployment target     | iOS `15.0`                  | `IPHONEOS_DEPLOYMENT_TARGET` in `ios/Runner.xcodeproj/project.pbxproj` |
| Xcode                 | 15+ (Flutter recommends 16) | Flutter 3.47.7 `xcodeRequiredVersion`                         |
| Plugin dependencies   | Swift Package Manager       | `FlutterGeneratedPluginSwiftPackage`, generated under `ios/Flutter/ephemeral/` |
| CocoaPods             | Not used                    | No `ios/Podfile`                                              |

Flutter 3.47.7's iOS migrators raised the deployment target from 13.0 to 15.0 and added the Swift Package Manager integration: a local package reference and product dependency in `project.pbxproj`, and the "Run Prepare Flutter Framework Script" pre-action in `Runner.xcscheme`. Swift Package Manager is on by default on the stable channel, so nothing in `pubspec.yaml` or `flutter config` turns it on. **Users on iOS 13 and 14 cannot install releases built from this project any more.**

Every iOS plugin in the graph ships a `Package.swift`: `package_info_plus`, `url_launcher_ios` and `webview_flutter_wkwebview`. `path_provider_foundation` 2.6 has no native plugin code. It calls Foundation through `objective_c` FFI. `sqlite3` and `objective_c` ship their libraries as build-hook code assets, which Flutter embeds as frameworks with or without a package manager. With all plugins on Swift Package Manager, Flutter prints "your project still has CocoaPods integration" and asks you to delete the Podfile and the `Pods-Runner.*.xcconfig` includes in `ios/Flutter/{Debug,Release}.xcconfig`. Both are gone. `pod deintegrate` had nothing to remove, because `pod install` output was never committed. When Swift Package Manager is in use and there is no Podfile, the tool skips CocoaPods (`processPodsIfNeeded` in `flutter_tools/lib/src/macos/cocoapod_utils.dart`).

If a plugin without a `Package.swift` is added, `flutter build ios` writes a new Podfile and needs CocoaPods again. `ios-nightly.yml` fails when that happens, so the change is deliberate. To accept it, commit the generated Podfile and the Pods `#include?` lines Flutter adds to `ios/Flutter/{Debug,Release}.xcconfig`, and remove that check. `macos/` is not a supported target and still uses its original CocoaPods setup. Flutter migrates it the same way on the first `flutter build macos`.

## Build-runner consumers

Code generation is required whenever any of these annotations changes — the build will fail loudly if generated files are stale:

- `@freezed` → `freezed` / `freezed_annotation`
- `@riverpod` → `riverpod_generator`
- `@DriftDatabase` / `@DataClassName` → `drift_dev`

Run `dart run build_runner build --delete-conflicting-outputs` (or the `watch` variant) after touching any of them.

## Committed `pubspec.lock`

`pubspec.lock` is committed (the root `.gitignore` ignores `*.lock` but re-includes `!/pubspec.lock`), as Dart recommends for applications. Before this, every CI run resolved packages fresh, so a new release of any transitive package could change the build with no diff in the repo. The sharpest case is `sqlite3 3.x`: its version selects the prebuilt SQLite library that is downloaded and shipped (see the SQLite note in `PRD.md`), so a new `sqlite3` release could have changed the database engine in release builds silently.

- Every workflow runs `flutter pub get --enforce-lockfile`, which fails if `pubspec.lock` is missing, does not satisfy `pubspec.yaml`, or would change.
- To change a dependency, edit `pubspec.yaml`, run `flutter pub get` (or `flutter pub upgrade <package>`), and commit `pubspec.yaml` and `pubspec.lock` together.
- `pubspec.lock` is in the `ios-nightly.yml` path filter, so a lockfile-only upgrade still triggers the iOS build.

