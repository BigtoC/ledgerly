---
title: Flutter widget-test and on-device verification gotchas from the CSV export
date: 2026-10-30
category: docs/solutions/developer-experience/
module: settings/csv_export (tests, device verification, size check)
problem_type: developer_experience
component: testing_framework
related_components: [development_workflow, tooling]
severity: medium
applies_when:
  - Asserting on encoded bytes such as a UTF-8 BOM after decoding them
  - Widget-testing Flutter framework dialogs (DateRangePicker) or lazy ListViews at 2x text scale
  - Pumping more than one ProviderScope app inside a single testWidgets
  - Installing a branch build on a real device that holds personal data, or capturing PR screenshots
  - Running the AGENTS.md APK size check or per-commit bisect checks from a worktree
tags: [flutter-test, utf8-bom, ahem-font, widget-test, adb, apk-size, worktree, bisect]
---

# Flutter widget-test and on-device verification gotchas from the CSV export

## Context

While building CSV export (PR #69), several tests failed for reasons unrelated to the feature, and checking the build on a phone, measuring APK size and checking each commit for bisect each had a trap. Most look like feature bugs at first and invite the wrong fix.

## Guidance

### 1. `utf8.decode` hides a leading BOM: assert the raw bytes

**Symptom:** `expect(text.startsWith('\ufeff'), isTrue)` failed (`Expected: true, Actual: <false>`) even though `Csv(addBom: true)` from `csv` 8.0.0 writes `\ufeff`, as its encoder source shows. The decoded string did not start with the BOM. We infer that `utf8.decode` drops it, because the byte-level check passed; the SDK code was not traced.

**Fix** (`test/unit/utils/transactions_csv_test.dart`): check the three BOM bytes, then decode the rest.

```dart
List<String> _lines(List<int> bytes) {
  expect(bytes.take(3), [0xEF, 0xBB, 0xBF], reason: 'UTF-8 BOM for Excel');
  return utf8.decode(bytes.sublist(3)).split('\r\n');
}
```

### 2. `DateRangePickerDialog` overflows under the Ahem font

**Symptom:** `A RenderFlex overflowed by 44 pixels on the right` at a 400×800 test view. The overflow is in the picker's own header (`Row ← Column ← … ← PreferredSize`, `w<=264`), not in app layout. The likely cause, not verified, is the Ahem test font: it draws every glyph as a full square, so the framework header is much wider than with real fonts.

**Fix:** pass `size: const Size(800, 1000)` to `_pump` for the picker test only (`csv_export_screen_test.dart`, CE05). Keep the other tests at phone width so real overflows still show.

### 3. Two `_pump` calls in one `testWidgets` leave a pending timer

**Symptom:** pumping a second `UncontrolledProviderScope` app in the same test failed with `A Timer is still pending even after the widget tree was disposed` (`'!timersPending'`). The root cause was not diagnosed.

**Fix used:** one state per test (CE07 done, CE08 failed). `csv_import_screen_test.dart` pumps several states per test and passes `key: UniqueKey()` to the scope. That may be the alternative, but it was not tried here.

### 4. A lazy `ListView` at 2× text scale doesn't build lower children

**Symptom:** `Found 0 widgets with key [<'csvExportButton'>]` at `textScale: 2.0`. The page body is a `ListView`, and at 2× its lower children fall outside the viewport and cache extent, so they are never built. `skipOffstage: false` does not help, because the widgets don't exist.

**Fix:** check for overflow, scroll the last child into view, then check again.

```dart
expect(tester.takeException(), isNull);
await tester.scrollUntilVisible(find.text('Exported 12 transactions'), 200);
expect(tester.takeException(), isNull);
expect(_exportButton(), findsOneWidget);
```

### 5. Checking on a device that holds real data

- **Install without risking the ledger.** Use `adb install -r <apk>`: it replaces the app and keeps its data, and on a signature mismatch it fails instead of uninstalling. Check what is installed first with `adb shell dumpsys package com.example.ledgerly | grep -E "versionName|pkgFlags|firstInstallTime"`. Here the existing debug install had a matching signature, and the install reported `Success` with the data intact. Whether `flutter run` would uninstall, and so wipe the data, was not tested; the fail-safe is why `adb install -r` was used.
- **Keep real data out of PR screenshots.** The splash screen (personal display text), Home (amounts, memos) and the system save dialog (it listed personal files in Download) all show user data. Screenshot only screens without it. Get tap targets from `adb shell uiautomator dump` instead of screenshots: Flutter's semantics appear as `content-desc`.
- **Don't write a file of real data.** Cancel the save dialog. One BACK did not close the DocumentsUI picker. Confirm the app is in front again with `adb shell dumpsys activity activities | grep -m1 topResumedActivity`.

### 6. Size check without release signing keys

**Symptom:** in a worktree, `flutter build apk --release` failed with `Release builds require android/key.properties with keyAlias, keyPassword, storeFile, and storePassword.` Those keys live only in the main checkout and should not be copied around.

**Fix:** build debug APKs of `main` and the branch, then compare each entry's compressed size. Don't compare the total APK sizes: the two were close enough to look unchanged, yet the entries added up to roughly 1 MB of difference.

```python
import zipfile
def sizes(p): return {i.filename: i.compress_size for i in zipfile.ZipFile(p).infolist()}
m, b = sizes('main-debug.apk'), sizes('branch-debug.apk')
for n in sorted(set(m) | set(b)):
    d = b.get(n, 0) - m.get(n, 0)
    if abs(d) > 500: print(n, d)
```

A plugin's real cost is the dex delta: `file_picker` added `classes.dex` +192,625 bytes and `classes2.dex` +33,801 bytes, compressed, before R8. Ignore `assets/flutter_assets/kernel_blob.bin` (+729,574 here). It is the debug-only Dart kernel and doesn't ship in release.

### 7. Checking that each commit builds on its own (bisect)

`AGENTS.md` requires each commit to analyze and test on its own. To check that, run this for each intermediate commit:

```bash
git checkout -q <sha> && flutter pub get   # pub get matters when pubspec.lock changed
dart analyze --fatal-infos
flutter test <the tests that commit touches>
git checkout -q <branch>
```

The tip still gets the full CI sequence (format check, analyze, `flutter test`).

### 8. A local iOS build that fails before compiling

**Symptom:** `flutter build ios --no-codesign --debug` printed `No Xcode build settings have been found`, and `xcodebuild -showBuildSettings` reported `Found no destinations for the scheme 'Runner' and action build.` That points at the local Xcode install, most likely a missing iOS platform (inferred), not at the change.

**Still checkable locally:** `ls ios/Flutter/ephemeral/Packages/.packages | grep <plugin>` shows the plugin resolved through SPM (`file_picker_darwin-2.4.0`), and `ios/Podfile` was not created. Leave the real compile to the iOS CI job, which runs on PRs that touch `pubspec.yaml`, `pubspec.lock` or `ios/`.

## Why This Matters

The test failures send you toward the wrong fix: changing app layout to fit a framework header, or doubting a BOM writer that works. The device and size traps are worse: one could wipe or leak real financial data, and the other gives a reassuring number that hides about 0.2 MB of new dex.

## When to Apply

- Asserting on bytes the app writes (BOM, line endings), not on decoded text
- Widget tests that open Flutter framework dialogs or pickers, or that run a `ListView` page at 2× text scale
- Screen test files that cover several controller states
- Installing a development build on a phone that has the app with real data, or taking screenshots for a PR
- Adding a native plugin (size check, iOS SPM check), or splitting a branch into commits that must each build

## Related

- `docs/solutions/test-failures/analysis-manage-accounts-review-followups-2026-05-05.md`: another test-only header overflow, fixed with a `MediaQueryData(size: ...)` wrapper rather than `setSurfaceSize`.
- `docs/solutions/performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md`: the APK size rule, and inspecting `flutter_assets` when no signing key is available; section 6 adds the per-entry comparison.
- `docs/solutions/architecture-patterns/android-in-app-apk-self-update-packageinstaller-session.md`: PackageInstaller status 5 is a signing-key conflict, the same mismatch section 5 avoids.
- `docs/architecture/testing.md` (the `tester.runAsync` and `@Dependencies` rules for `UncontrolledProviderScope` tests) and `docs/architecture/dependencies.md` (the iOS SPM toolchain).
- PR #69 (CSV export).
