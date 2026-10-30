# In-App APK Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tapping the Settings "new version" pill downloads the release APK inside Ledgerly, verifies its SHA-256 and hands it to the Android package installer. Today the pill opens the APK URL in the system browser.

**Architecture:** dio downloads the file into `<cacheDir>/updates/`. The repository checks it against the `digest` the GitHub API publishes for each release asset. A small Kotlin MethodChannel (`ledgerly/apk_installer`) streams the file into a `PackageInstaller` session. On Android 12+ it asks for a prompt-free self-update with `setRequireUserAction(USER_ACTION_NOT_REQUIRED)` and `UPDATE_PACKAGES_WITHOUT_USER_ACTION`, and falls back to the system confirm dialog when Android requires one. A keep-alive `AppUpdateController` owns the flow state. `NewVersionBadge` renders the state and keeps the browser as the fallback on every failure.

**Tech Stack:** Flutter 3.47, Riverpod 3 (generator), Freezed, dio 5, `crypto` (pure Dart, promoted from transitive), `path_provider`, Kotlin (framework APIs only, no new Gradle deps).

**Decisions already made with the user (2026-10-30):**
- Prompt-free self-update on Android 12+: **yes**.
- SHA-256 is checked **in Dart** with `crypto`.
- **Foreground-only download** in v1: no service and no notification.
- The `com.example.ledgerly` applicationId is **out of scope**.

**Deliberately out of v1, following YAGNI:**
- download cancel and resume;
- a background or foreground-service download;
- a metered-network warning;
- a lifecycle listener after the permission grant, because the user taps "install" again instead;
- a debug-build bypass, because a debug build simply hits `signatureConflict` and the browser fallback;
- size and redirect-host checks, because the SHA-256 check already covers integrity.

---

## Background facts (verified during research)

These were checked against developer.android.com, AOSP and the live GitHub API.

- **GitHub release assets** already include `"digest": "sha256:<64 hex>"` and `"size": <int>`. For example, `ledgerly-v0.7.3-arm64-v8a.apk` is `sha256:41733337…fad4` and 25568852 bytes.
- **`PackageInstaller` session API** is the recommended install path, and `ACTION_INSTALL_PACKAGE` is deprecated in API 29.
  - Copying the file into the session needs no FileProvider and no storage permission.
  - The session's `commit()` needs a **mutable** `PendingIntent` on target 35+ and an **explicit** Intent on target 34+.
  - `STATUS_PENDING_USER_ACTION` (-1) delivers `Intent.EXTRA_INTENT`, which must be launched to show the confirm dialog.
  - Final status codes: `SUCCESS=0`, `FAILURE=1`, `BLOCKED=2`, `ABORTED=3`, `INVALID=4`, `CONFLICT=5`, `STORAGE=6`, `INCOMPATIBLE=7`, `TIMEOUT=8`.
- **Install permission:** `REQUEST_INSTALL_PACKAGES` is required on target 26+. The per-app "Install unknown apps" toggle is read with `packageManager.canRequestPackageInstalls()` and opened with `Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES` plus `package:<id>`. On Android 11, turning the toggle on kills the app.
- **Prompt-free self-update (API 31+):** `setRequireUserAction(USER_ACTION_NOT_REQUIRED)` together with the normal permission `UPDATE_PACKAGES_WITHOUT_USER_ACTION`. Android may still require the dialog, so `PENDING_USER_ACTION` must always be handled.
- **Process lifetime:** a successful self-update kills the running process, so the Dart `install` future never completes on success.
- **Signing:** an APK signed with a different key fails with `STATUS_FAILURE_CONFLICT`, which is what happens to debug builds.
- **Flutter defaults:** minSdk 24, targetSdk 36.

## File map

| File | Status | Responsibility |
|---|---|---|
| `lib/data/services/app_release_service.dart` | modify | Parse each asset's `digest` and `size`; add `download()` |
| `lib/data/services/apk_installer_service.dart` | create | Thin MethodChannel wrapper (`canRequestInstalls`, `openInstallSettings`, `install`) |
| `lib/data/models/app_update.dart` | create | Freezed `AppUpdate` value: version, file name, URL, sha256, size |
| `lib/data/repositories/app_update_repository.dart` | modify | `findUpdate()` returns `AppUpdate?`; adds `download` + verify, `canInstall`, `openInstallSettings`, `install` → `InstallOutcome`, `cleanUp`, typed exceptions |
| `lib/app/providers/app_update_provider.dart` | modify | Wires installer and updates dir; state becomes `AppUpdate?`; `checkAfter` cleans stale files |
| `lib/features/settings/app_update_state.dart` | create | Freezed sealed flow state + `UpdateFailure` enum |
| `lib/features/settings/app_update_controller.dart` | create | Keep-alive notifier: download → permission → install |
| `lib/features/settings/widgets/new_version_badge.dart` | modify | ConsumerWidget: confirm dialog, progress label, SnackBars with browser fallback |
| `lib/features/settings/settings_screen.dart` | modify | Passes `AppUpdate` to the badge |
| `android/app/src/main/AndroidManifest.xml` | modify | Two permissions + the receiver |
| `android/app/src/main/kotlin/com/example/ledgerly/MainActivity.kt` | modify | Channel handler + session install |
| `android/app/src/main/kotlin/com/example/ledgerly/InstallStatusReceiver.kt` | create | Session status → confirm dialog or channel result |
| `l10n/app_en.arb`, `app_zh_CN.arb`, `app_zh_TW.arb` | modify | New `settingsUpdate*` keys (`app_zh.arb` untouched) |
| `pubspec.yaml` | modify | `crypto` as a direct dependency |
| docs: `docs/architecture/bootstrap.md`, `docs/architecture/testing.md` | modify | Describe the new flow and tests |

Tests:
- `test/unit/services/app_release_service_test.dart`
- `test/unit/services/apk_installer_service_test.dart` (new)
- `test/unit/repositories/app_update_repository_test.dart`
- `test/unit/providers/available_app_update_provider_test.dart`
- `test/unit/controllers/app_update_controller_test.dart` (new)
- `test/widget/features/settings/new_version_badge_test.dart`
- `test/widget/features/settings/settings_screen_test.dart`
- `test/widget/app/adaptive_shell_test.dart`
- `test/unit/l10n/arb_audit_test.dart`
- `test/unit/app/android_in_app_update_manifest_test.dart` (new)

## Commands used throughout

```bash
dart run build_runner build --delete-conflicting-outputs   # after any @freezed / @riverpod edit
flutter gen-l10n                                           # after any .arb edit
flutter test <path>                                        # targeted tests
flutter test test/unit/architecture/                       # layer rules, every commit
dart format lib test && dart analyze --fatal-infos         # every commit
```

Every commit must pass `dart analyze --fatal-infos` and the full `flutter test`. Commit messages use Conventional Commits with the scopes `data`, `app`, `settings`, `l10n`, `deps` and `docs`.

---

### Task 1: Release service parses digest and size and can download

**Files:**
- Modify: `lib/data/services/app_release_service.dart`
- Modify: `test/unit/services/app_release_service_test.dart`
- Modify: `test/unit/repositories/app_update_repository_test.dart` (the `_Release` typedef only)

- [ ] **Step 1: Write failing tests.** Add the following to `app_release_service_test.dart`, and update the two existing `expect(release.assets, [...])` expectations to include `digest: null, size: null`, since their fixtures have no digest or size.

```dart
    test('parses digest and size when present', () async {
      stubBody({
        'tag_name': 'v0.7.3',
        'assets': [
          {
            'name': 'ledgerly-v0.7.3-arm64-v8a.apk',
            'browser_download_url': 'https://example.com/arm64.apk',
            'digest': 'sha256:41733337fdf4406a32e99c13108afd9b1be786f28c85e69ff2f375adf199fad4',
            'size': 25568852,
          },
        ],
      });

      final release = await service.fetchLatestRelease();

      expect(release!.assets.single, (
        name: 'ledgerly-v0.7.3-arm64-v8a.apk',
        url: 'https://example.com/arm64.apk',
        digest:
            'sha256:41733337fdf4406a32e99c13108afd9b1be786f28c85e69ff2f375adf199fad4',
        size: 25568852,
      ));
    });

    test('non-string digest and non-int size become null', () async {
      stubBody({
        'tag_name': 'v0.7.3',
        'assets': [
          {
            'name': 'a.apk',
            'browser_download_url': 'https://example.com/a.apk',
            'digest': 42,
            'size': '1',
          },
        ],
      });

      final asset = (await service.fetchLatestRelease())!.assets.single;
      expect(asset.digest, isNull);
      expect(asset.size, isNull);
    });
```

Add a new group:

```dart
  group('AppReleaseService.download', () {
    test('downloads the URL to the path and reports progress', () async {
      final url = Uri.parse('https://example.com/a.apk');
      when(
        () => mockDio.downloadUri(
          url,
          '/tmp/a.apk.part',
          onReceiveProgress: any(named: 'onReceiveProgress'),
          deleteOnError: true,
        ),
      ).thenAnswer((inv) async {
        final cb =
            inv.namedArguments[#onReceiveProgress] as ProgressCallback;
        cb(5, 10);
        return Response<dynamic>(requestOptions: RequestOptions());
      });
      final progress = <(int, int)>[];

      await service.download(
        url,
        '/tmp/a.apk.part',
        onProgress: (r, t) => progress.add((r, t)),
      );

      expect(progress, [(5, 10)]);
    });
  });
```

- [ ] **Step 2: Run the tests and watch them fail.** Run `flutter test test/unit/services/app_release_service_test.dart`. Expect a compile error because the record has no `digest`/`size` and `download` is undefined.

- [ ] **Step 3: Implement.** Replace the record type and the parsing in `app_release_service.dart`, and add the method.

```dart
/// One release asset. `digest` is GitHub's `sha256:<hex>` string and
/// `size` its byte count; either is null when the API omits it.
typedef ReleaseAsset = ({String name, String url, String? digest, int? size});

  Future<({String tagName, List<ReleaseAsset> assets})?>
  fetchLatestRelease() async {
    // ...unchanged GET...
    if (response.data case {
      'tag_name': final String tagName,
      'assets': final List<dynamic> assets,
    }) {
      return (
        tagName: tagName,
        assets: [
          for (final asset in assets)
            if (asset case {
              'name': final String name,
              'browser_download_url': final String url,
            })
              (
                name: name,
                url: url,
                digest: switch (asset['digest']) {
                  final String d => d,
                  _ => null,
                },
                size: switch (asset['size']) {
                  final int s => s,
                  _ => null,
                },
              ),
        ],
      );
    }
    return null;
  }

  /// Downloads [url] to [path], following redirects. dio deletes the
  /// partial file when the download fails. Throws [DioException] on
  /// network or HTTP errors.
  Future<void> download(
    Uri url,
    String path, {
    void Function(int received, int total)? onProgress,
  }) => _dio.downloadUri(
    url,
    path,
    onReceiveProgress: onProgress,
    deleteOnError: true,
  );
```

Also add a sentence to the class doc: the download is a GET of a release asset URL with no user data.

- [ ] **Step 4: Keep the repository tests compiling.** In `app_update_repository_test.dart`:
  - change the typedef to `typedef _Release = ({String tagName, List<ReleaseAsset> assets});`;
  - give every asset literal `digest: null, size: null`.

The `const` lists stay `const`. Asset literals become, for example, `(name: 'ledgerly-v0.7.2-arm64-v8a.apk', url: _arm64Url, digest: null, size: null)`.

- [ ] **Step 5: Run the tests.** `flutter test test/unit/services/app_release_service_test.dart test/unit/repositories/app_update_repository_test.dart` should pass. Then run `dart analyze --fatal-infos`.

- [ ] **Step 6: Commit.**

```bash
git add lib/data/services/app_release_service.dart test/unit/services/app_release_service_test.dart test/unit/repositories/app_update_repository_test.dart
git commit -m "feat(data): read release asset digests and download assets"
```

---

### Task 2: ApkInstallerService MethodChannel wrapper

**Files:**
- Create: `lib/data/services/apk_installer_service.dart`
- Create: `test/unit/services/apk_installer_service_test.dart`

- [ ] **Step 1: Write a failing test.**

```dart
// Guards the Dart side of the `ledgerly/apk_installer` channel: method
// names, arguments and result decoding must match MainActivity.kt.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/services/apk_installer_service.dart';

const _channel = MethodChannel('ledgerly/apk_installer');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  void handle(Object? Function(MethodCall call) reply) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return reply(call);
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null),
    );
  }

  setUp(calls.clear);

  test('canRequestInstalls returns the platform bool', () async {
    handle((_) => true);
    expect(await ApkInstallerService().canRequestInstalls(), isTrue);
    expect(calls.single.method, 'canRequestInstalls');
  });

  test('openInstallSettings invokes the platform method', () async {
    handle((_) => null);
    await ApkInstallerService().openInstallSettings();
    expect(calls.single.method, 'openInstallSettings');
  });

  test('install sends the path and returns the session status', () async {
    handle((_) => 3);
    expect(await ApkInstallerService().install('/c/u/a.apk'), 3);
    expect(calls.single.method, 'install');
    expect(calls.single.arguments, {'path': '/c/u/a.apk'});
  });

  test('a null install result counts as STATUS_FAILURE (1)', () async {
    handle((_) => null);
    expect(await ApkInstallerService().install('/a.apk'), 1);
  });
}
```

- [ ] **Step 2: Run the test and watch it fail.** Run `flutter test test/unit/services/apk_installer_service_test.dart`. Expect the import to fail.

- [ ] **Step 3: Implement.**

```dart
import 'package:flutter/services.dart';

/// Hands a downloaded APK to Android's package installer through the
/// `ledgerly/apk_installer` channel implemented in `MainActivity.kt`.
///
/// Android only: callers check `AppUpdateRepository.isSupported` first.
class ApkInstallerService {
  const ApkInstallerService();

  static const _channel = MethodChannel('ledgerly/apk_installer');

  /// Whether the user has allowed Ledgerly to install apps
  /// ("Install unknown apps"). Always true below Android 8.
  Future<bool> canRequestInstalls() async =>
      await _channel.invokeMethod<bool>('canRequestInstalls') ?? false;

  /// Opens the system "Install unknown apps" page for Ledgerly.
  Future<void> openInstallSettings() =>
      _channel.invokeMethod<void>('openInstallSettings');

  /// Installs the APK at [path] and returns the final
  /// `PackageInstaller.STATUS_*` code. On success Android kills this
  /// process while updating it, so the future usually never completes.
  Future<int> install(String path) async =>
      await _channel.invokeMethod<int>('install', {'path': path}) ?? 1;
}
```

- [ ] **Step 4: Run the tests.** `flutter test test/unit/services/apk_installer_service_test.dart test/unit/architecture/` should pass.

- [ ] **Step 5: Commit.**

```bash
git add lib/data/services/apk_installer_service.dart test/unit/services/apk_installer_service_test.dart
git commit -m "feat(data): add an APK installer platform channel service"
```

---

### Task 3: `AppUpdate` model flows from repository to badge

`findUpdate()` now returns `AppUpdate?` instead of `Uri?`. The badge keeps its browser behaviour by reading `update.apkUrl`. These files cannot compile apart, so this is one commit; say so in the commit body.

**Files:**
- Create: `lib/data/models/app_update.dart`
- Modify: `lib/data/repositories/app_update_repository.dart`
- Modify: `lib/app/providers/app_update_provider.dart`
- Modify: `lib/app/widgets/adaptive_shell.dart`, the `select` lambda parameter name only (`url` → `update`)
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/settings/widgets/new_version_badge.dart`
- Tests:
  - `test/unit/repositories/app_update_repository_test.dart`
  - `test/unit/providers/available_app_update_provider_test.dart`
  - `test/widget/features/settings/new_version_badge_test.dart`
  - `test/widget/features/settings/settings_screen_test.dart`
  - `test/widget/app/adaptive_shell_test.dart`
  - `test/widget/app/app_update_check_test.dart` (if it references `Uri` state)

- [ ] **Step 1: Create the model.**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_update.freezed.dart';

/// A newer GitHub release APK built for this device's ABI.
@freezed
abstract class AppUpdate with _$AppUpdate {
  const factory AppUpdate({
    /// Release tag, e.g. `v0.7.3`.
    required String version,

    /// Asset name, e.g. `ledgerly-v0.7.3-arm64-v8a.apk`.
    required String fileName,

    /// https `browser_download_url` of the asset.
    required Uri apkUrl,

    /// Lowercase hex SHA-256 from the asset's GitHub `digest`. Null, along
    /// with [sizeBytes], when either is missing or malformed: the update
    /// can then only be opened in the browser.
    String? sha256,

    /// Asset size in bytes, shown before downloading.
    int? sizeBytes,
  }) = _AppUpdate;
}
```

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 2: Change the repository tests to expect `AppUpdate`.** In `app_update_repository_test.dart`:
  - replace the `Uri.parse(_armXUrl)` expectations with `isA<AppUpdate>().having((u) => u.apkUrl, 'apkUrl', Uri.parse(_armXUrl))`;
  - add the tests below. Here `_digest` is `'sha256:' + 'ab' * 32`, and `_hex` is `'ab' * 32`.

```dart
    test('carries tag, file name, sha256 and size', () async {
      stubRelease(
        _release(
          assets: const [
            (
              name: 'ledgerly-v0.7.2-arm64-v8a.apk',
              url: _arm64Url,
              digest: _digest,
              size: 1234,
            ),
          ],
        ),
      );
      expect(
        await repo().findUpdate(),
        AppUpdate(
          version: 'v0.7.2',
          fileName: 'ledgerly-v0.7.2-arm64-v8a.apk',
          apkUrl: Uri.parse(_arm64Url),
          sha256: _hex,
          sizeBytes: 1234,
        ),
      );
    });

    for (final (label, digest, size) in [
      ('missing digest', null, 1234),
      ('non-sha256 digest', 'md5:abcd', 1234),
      ('short hex', 'sha256:abcd', 1234),
      ('missing size', _digest, null),
    ]) {
      test('$label: sha256 and size are null (browser only)', () async {
        stubRelease(
          _release(
            assets: [
              (
                name: 'ledgerly-v0.7.2-arm64-v8a.apk',
                url: _arm64Url,
                digest: digest,
                size: size,
              ),
            ],
          ),
        );
        final update = await repo().findUpdate();
        expect(update!.sha256, isNull);
        expect(update.sizeBytes, isNull);
      });
    }

    test('uppercase hex digest is normalised to lowercase', () async {
      stubRelease(
        _release(
          assets: [
            (
              name: 'ledgerly-v0.7.2-arm64-v8a.apk',
              url: _arm64Url,
              digest: 'sha256:${'AB' * 32}',
              size: 1,
            ),
          ],
        ),
      );
      expect((await repo().findUpdate())!.sha256, _hex);
    });
```

- [ ] **Step 3: Run the tests and watch them fail.** Run `flutter test test/unit/repositories/app_update_repository_test.dart`.

- [ ] **Step 4: Implement `findUpdate`.**

```dart
  static final _sha256Digest = RegExp(r'^sha256:([0-9a-fA-F]{64})$');

  /// The newer release APK for this device's ABI, or null: off Android,
  /// not newer, no matching https asset, or any failure.
  Future<AppUpdate?> findUpdate() async {
    // ...same guards as today up to `asset`...
      final uri = asset == null ? null : Uri.tryParse(asset.url);
      if (asset == null || uri == null || !uri.isScheme('https')) return null;
      final hex = _sha256Digest.firstMatch(asset.digest ?? '')?[1];
      final inApp = hex != null && asset.size != null;
      return AppUpdate(
        version: release.tagName,
        fileName: apkName,
        apkUrl: uri,
        sha256: inApp ? hex.toLowerCase() : null,
        sizeBytes: inApp ? asset.size : null,
      );
```

Update the doc comment to match.

- [ ] **Step 5: Ripple `AppUpdate?` through the provider, shell and badge.**
  - `app_update_provider.dart`: change `Uri? build()` to `AppUpdate? build()`; `state = url` becomes `state = update`. Update the doc comment from "APK download URL" to "The newer release".
  - `adaptive_shell.dart:90`: `availableAppUpdateProvider.select((update) => update != null)`.
  - `settings_screen.dart`: `final update = ref.watch(availableAppUpdateProvider);` and `if (update != null) NewVersionBadge(update: update),`.
  - `new_version_badge.dart`: the constructor takes `required this.update` (`final AppUpdate update;`), and `_open` uses `update.apkUrl`. It imports `../../../data/models/app_update.dart`, which the widget rules allow.
  - In the tests, the `_apkUrl` fixtures become `AppUpdate(version: 'v0.7.2', fileName: 'ledgerly-v0.7.2-arm64-v8a.apk', apkUrl: Uri.parse('…'))`:
    - `available_app_update_provider_test.dart`: `findUpdate()` returns the `_update` fixture, and the state is compared with it.
    - `adaptive_shell_test.dart`: the `Uri? update` parameter becomes `AppUpdate? update`.
    - `settings_screen_test.dart`: the override and the SS09 check `tester.widget<NewVersionBadge>(...).update.apkUrl`.
    - `new_version_badge_test.dart`: `NewVersionBadge(update: _update)`, and keep asserting the launched URL is `_update.apkUrl`.

- [ ] **Step 6: Run the tests.** `flutter test` should pass in full, along with `dart analyze --fatal-infos`.

- [ ] **Step 7: Commit.**

```bash
git add -A lib test
git commit -m "refactor(data,settings): return an AppUpdate from the update check" -m "findUpdate now returns the release tag, asset name, URL and, when GitHub publishes them, the SHA-256 digest and size. The provider, shell, settings screen and badge change in the same commit because they share the provider's type."
```

---

### Task 4: Repository download, verify, install and clean-up

**Files:**
- Modify: `pubspec.yaml` (add `crypto: ^3.0.6` under the `dio` entry with a comment; run `flutter pub get`, then check that `pubspec.lock` shows `crypto` as `direct main`)
- Modify: `lib/data/repositories/app_update_repository.dart`
- Modify: `lib/app/providers/app_update_provider.dart`
- Tests: `test/unit/repositories/app_update_repository_test.dart` and `test/unit/providers/available_app_update_provider_test.dart`

Exceptions and the outcome enum stay local to `app_update_repository.dart`, following the same pattern as the category-only exceptions.

- [ ] **Step 1: Add the dependency.** Add `crypto` to `pubspec.yaml` with the comment `# SHA-256 of downloaded update APKs (pure Dart, no assets)`. Run `flutter pub get`.

- [ ] **Step 2: Write failing repository tests.** The `repo()` helper gains two arguments: `installer: installer` (a `MockApkInstallerService`) and `updatesDir: () async => dir`. `dir` is a fresh `Directory.systemTemp.createTempSync('upd')`, deleted in `addTearDown`. Fixtures:

```dart
final _bytes = utf8.encode('fake apk bytes');
final _goodHex = sha256.convert(_bytes).toString();
AppUpdate _upd({String? hex}) => AppUpdate(
  version: 'v0.7.2',
  fileName: 'ledgerly-v0.7.2-arm64-v8a.apk',
  apkUrl: Uri.parse(_arm64Url),
  sha256: hex ?? _goodHex,
  sizeBytes: _bytes.length,
);

void stubDownloadWrites(List<int> bytes) {
  when(
    () => service.download(any(), any(), onProgress: any(named: 'onProgress')),
  ).thenAnswer((inv) async {
    final cb = inv.namedArguments[#onProgress] as void Function(int, int)?;
    cb?.call(bytes.length, bytes.length);
    File(inv.positionalArguments[1] as String).writeAsBytesSync(bytes);
  });
}
```

Register `setUpAll(() => registerFallbackValue(Uri()))`.

```dart
  group('AppUpdateRepository.download', () {
    test('verified download is renamed from .part and its path returned', () async {
      stubDownloadWrites(_bytes);
      final progress = <double>[];
      final path = await repo().download(_upd(), onProgress: progress.add);
      expect(path, '${dir.path}/ledgerly-v0.7.2-arm64-v8a.apk');
      expect(File(path).readAsBytesSync(), _bytes);
      expect(File('$path.part').existsSync(), isFalse);
      expect(progress, [1.0]);
    });

    test('hash mismatch deletes the file and throws', () async {
      stubDownloadWrites(utf8.encode('tampered'));
      await expectLater(
        repo().download(_upd()),
        throwsA(isA<UpdateChecksumException>()),
      );
      expect(dir.listSync(), isEmpty);
    });

    test('an already verified file is reused without downloading', () async {
      File('${dir.path}/ledgerly-v0.7.2-arm64-v8a.apk').writeAsBytesSync(_bytes);
      await repo().download(_upd());
      verifyNever(
        () => service.download(any(), any(), onProgress: any(named: 'onProgress')),
      );
    });

    test('network failure throws UpdateDownloadException', () async {
      when(
        () => service.download(any(), any(), onProgress: any(named: 'onProgress')),
      ).thenThrow(DioException(requestOptions: RequestOptions()));
      await expectLater(
        repo().download(_upd()),
        throwsA(isA<UpdateDownloadException>()),
      );
    });

    test('file-system failure throws UpdateStorageException', () async {
      when(
        () => service.download(any(), any(), onProgress: any(named: 'onProgress')),
      ).thenThrow(const FileSystemException('No space left on device'));
      await expectLater(
        repo().download(_upd()),
        throwsA(isA<UpdateStorageException>()),
      );
    });
  });

  group('AppUpdateRepository.install', () {
    for (final (status, outcome) in [
      (0, InstallOutcome.success),
      (3, InstallOutcome.cancelled),
      (5, InstallOutcome.signatureConflict),
      (6, InstallOutcome.storage),
      (1, InstallOutcome.failed),
      (2, InstallOutcome.failed),
      (4, InstallOutcome.failed),
      (7, InstallOutcome.failed),
      (8, InstallOutcome.failed),
      (99, InstallOutcome.failed),
    ]) {
      test('status $status maps to $outcome', () async {
        when(() => installer.install('/a.apk')).thenAnswer((_) async => status);
        expect(await repo().install('/a.apk'), outcome);
      });
    }

    test('a channel error maps to failed', () async {
      when(() => installer.install(any())).thenThrow(PlatformException(code: 'x'));
      expect(await repo().install('/a.apk'), InstallOutcome.failed);
    });

    test('canInstall and openInstallSettings delegate', () async {
      when(() => installer.canRequestInstalls()).thenAnswer((_) async => true);
      when(() => installer.openInstallSettings()).thenAnswer((_) async {});
      expect(await repo().canInstall(), isTrue);
      await repo().openInstallSettings();
      verify(() => installer.openInstallSettings()).called(1);
    });
  });

  group('AppUpdateRepository.cleanUp', () {
    test('keeps only the verified APK of the given update', () async {
      final keep = File('${dir.path}/ledgerly-v0.7.2-arm64-v8a.apk')
        ..writeAsBytesSync(_bytes);
      final part = File('${keep.path}.part')..writeAsBytesSync(_bytes);
      final old = File('${dir.path}/ledgerly-v0.7.1-arm64-v8a.apk')
        ..writeAsBytesSync(_bytes);
      await repo().cleanUp(keep: _upd());
      expect(keep.existsSync(), isTrue);
      expect(part.existsSync(), isFalse);
      expect(old.existsSync(), isFalse);
    });

    test('with no update everything is removed', () async {
      File('${dir.path}/x.apk').writeAsBytesSync(_bytes);
      await repo().cleanUp(keep: null);
      expect(dir.listSync(), isEmpty);
    });
  });
```

- [ ] **Step 3: Run the tests and watch them fail.** Run `flutter test test/unit/repositories/app_update_repository_test.dart`.

- [ ] **Step 4: Implement.** Add these to `app_update_repository.dart`:

```dart
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../models/app_update.dart';
import '../services/apk_installer_service.dart';
import 'repository_exceptions.dart';

/// How a PackageInstaller session ended, when it ended without the
/// process being replaced.
enum InstallOutcome { success, cancelled, signatureConflict, storage, failed }

/// The update APK could not be downloaded (network or HTTP failure).
class UpdateDownloadException extends RepositoryException {
  const UpdateDownloadException() : super('Update download failed');
}

/// The downloaded APK's SHA-256 does not match the release digest.
class UpdateChecksumException extends RepositoryException {
  const UpdateChecksumException() : super('Update checksum mismatch');
}

/// The update APK could not be written to local storage.
class UpdateStorageException extends RepositoryException {
  const UpdateStorageException() : super('Update could not be stored');
}
```

Constructor:

```dart
  AppUpdateRepository(
    this._service, {
    required this._installer,
    required this._updatesDir,
    required this._installedVersion,
    required this._abi,
  });

  final ApkInstallerService _installer;

  /// Existing directory that holds downloaded update APKs.
  final Future<Directory> Function() _updatesDir;
```

Methods:

```dart
  /// Downloads [update] into the updates directory, verifies it against
  /// `update.sha256` and returns the verified APK's path. A file already
  /// verified earlier (e.g. before Android 11 restarted the app on the
  /// permission grant) is reused. [onProgress] gets 0.0–1.0.
  ///
  /// Requires `update.sha256`. Throws [UpdateDownloadException],
  /// [UpdateChecksumException] or [UpdateStorageException].
  Future<String> download(
    AppUpdate update, {
    void Function(double fraction)? onProgress,
  }) async {
    final expected = update.sha256!;
    try {
      final dir = await _updatesDir();
      final apk = File('${dir.path}/${update.fileName}');
      if (await apk.exists() && await _sha256Of(apk) == expected) {
        return apk.path;
      }
      final part = File('${apk.path}.part');
      await _service.download(
        update.apkUrl,
        part.path,
        onProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );
      if (await _sha256Of(part) != expected) {
        await part.delete();
        throw const UpdateChecksumException();
      }
      return (await part.rename(apk.path)).path;
    } on UpdateChecksumException {
      rethrow;
    } on FileSystemException catch (e) {
      debugPrint('AppUpdateRepository.download failed (${e.runtimeType})');
      throw const UpdateStorageException();
    } on Object catch (e) {
      debugPrint('AppUpdateRepository.download failed (${e.runtimeType})');
      throw const UpdateDownloadException();
    }
  }

  static Future<String> _sha256Of(File file) async =>
      (await sha256.bind(file.openRead()).first).toString();

  /// Whether Ledgerly may install apps ("Install unknown apps").
  Future<bool> canInstall() => _installer.canRequestInstalls();

  /// Opens the system page where the user allows Ledgerly to install apps.
  Future<void> openInstallSettings() => _installer.openInstallSettings();

  /// Installs the verified APK at [path]. On success Android replaces this
  /// process, so the returned future usually never completes.
  Future<InstallOutcome> install(String path) async {
    try {
      return switch (await _installer.install(path)) {
        0 => InstallOutcome.success,
        3 => InstallOutcome.cancelled,
        5 => InstallOutcome.signatureConflict,
        6 => InstallOutcome.storage,
        _ => InstallOutcome.failed,
      };
    } on PlatformException catch (e) {
      debugPrint('AppUpdateRepository.install failed (${e.runtimeType})');
      return InstallOutcome.failed;
    }
  }

  /// Deletes every file in the updates directory except [keep]'s APK:
  /// partial downloads, and the APK left behind by an update that has
  /// already been installed. Best effort; never throws.
  Future<void> cleanUp({required AppUpdate? keep}) async {
    try {
      final dir = await _updatesDir();
      await for (final entity in dir.list()) {
        if (entity.uri.pathSegments.last != keep?.fileName) {
          await entity.delete(recursive: true);
        }
      }
    } on Object catch (e) {
      debugPrint('AppUpdateRepository.cleanUp failed (${e.runtimeType})');
    }
  }
```

A `.part` file's name ends in `.part`, so it never equals `keep.fileName` and gets deleted.

- [ ] **Step 5: Wire the provider.** Write the provider test first. In `available_app_update_provider_test.dart`:
  - stub `when(() => repo.cleanUp(keep: any(named: 'keep'))).thenAnswer((_) async {});` in `setUp`;
  - register `registerFallbackValue(_update)` once;
  - add this test:

```dart
  test('cleans stale update files, keeping the found update', () async {
    when(() => repo.findUpdate()).thenAnswer((_) async => _update);
    await container
        .read(availableAppUpdateProvider.notifier)
        .checkAfter(Future.value());
    verify(() => repo.cleanUp(keep: _update)).called(1);
  });
```

Then implement:

```dart
@Riverpod(keepAlive: true)
AppUpdateRepository appUpdateRepository(Ref ref) => AppUpdateRepository(
  AppReleaseService(ref.watch(dioProvider)),
  installer: const ApkInstallerService(),
  updatesDir: () async =>
      Directory('${(await getTemporaryDirectory()).path}/updates')
          .create(recursive: true),
  installedVersion: () async => (await PackageInfo.fromPlatform()).version,
  abi: Abi.current(),
);
```

In `checkAfter`:

```dart
    final update = await repo.findUpdate();
    await repo.cleanUp(keep: update);
    if (ref.mounted) state = update;
```

`cleanUp` runs before the badge can appear, so it never races a download. Imports: `dart:io`, `package:path_provider/path_provider.dart`, `../../data/services/apk_installer_service.dart`. `lib/app/` has no `path_provider` ban; confirm with the architecture test.

Run `dart run build_runner build --delete-conflicting-outputs`, because the provider's source hash changes.

- [ ] **Step 6: Run the tests.** `flutter test` should pass in full, and `dart analyze --fatal-infos` should be clean.

- [ ] **Step 7: Commit.**

```bash
git add pubspec.yaml pubspec.lock lib test
git commit -m "feat(data): download, verify and install update APKs"
```

---

### Task 5: Android installer channel, receiver and manifest

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/src/main/kotlin/com/example/ledgerly/MainActivity.kt`
- Create: `android/app/src/main/kotlin/com/example/ledgerly/InstallStatusReceiver.kt`
- Create: `test/unit/app/android_in_app_update_manifest_test.dart`

- [ ] **Step 1: Write a failing config test.**

```dart
// Guards the Android pieces the in-app update needs: the install
// permissions and a non-exported receiver for PackageInstaller status.

import 'dart:io' show File;

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String manifest;
  late String activity;

  setUpAll(() {
    manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    activity = File(
      'android/app/src/main/kotlin/com/example/ledgerly/MainActivity.kt',
    ).readAsStringSync();
  });

  test('declares the install permissions', () {
    expect(manifest, contains('android.permission.REQUEST_INSTALL_PACKAGES'));
    expect(
      manifest,
      contains('android.permission.UPDATE_PACKAGES_WITHOUT_USER_ACTION'),
    );
  });

  test('status receiver is declared and not exported', () {
    expect(
      manifest,
      contains(
        '<receiver android:name=".InstallStatusReceiver" android:exported="false"',
      ),
    );
  });

  test('MainActivity registers the channel the Dart service uses', () {
    expect(activity, contains('"ledgerly/apk_installer"'));
  });
}
```

- [ ] **Step 2: Run the test and watch it fail.** Run `flutter test test/unit/app/android_in_app_update_manifest_test.dart`.

- [ ] **Step 3: Update the manifest.** Under the `INTERNET` permission, add:

```xml
    <!-- In-app update: hand the downloaded release APK to PackageInstaller. -->
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
    <!-- Android 12+: let a self-update skip the confirm dialog. -->
    <uses-permission android:name="android.permission.UPDATE_PACKAGES_WITHOUT_USER_ACTION"/>
```

Inside `<application>`, after `</activity>`, add:

```xml
        <!-- PackageInstaller session status for the in-app update. -->
        <receiver android:name=".InstallStatusReceiver" android:exported="false"/>
```

- [ ] **Step 4: Write `InstallStatusReceiver.kt`.**

```kotlin
package com.example.ledgerly

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.os.Build
import io.flutter.plugin.common.MethodChannel

/** Receives PackageInstaller session status for the in-app update. */
class InstallStatusReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val status = intent.getIntExtra(
            PackageInstaller.EXTRA_STATUS,
            PackageInstaller.STATUS_FAILURE,
        )
        if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
            val confirm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_INTENT)
            }
            if (confirm != null) {
                // The system confirm dialog; the final status arrives later.
                context.startActivity(confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return
            }
            finish(PackageInstaller.STATUS_FAILURE)
            return
        }
        finish(status)
    }

    companion object {
        /** Channel result of the install in flight; completed once. */
        var pending: MethodChannel.Result? = null

        fun finish(status: Int) {
            pending?.success(status)
            pending = null
        }
    }
}
```

- [ ] **Step 5: Write `MainActivity.kt`.**

```kotlin
package com.example.ledgerly

import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageInstaller
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ledgerly/apk_installer")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canRequestInstalls" -> result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
                            packageManager.canRequestPackageInstalls(),
                    )
                    "openInstallSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                    Uri.parse("package:$packageName"),
                                ),
                            )
                        }
                        result.success(null)
                    }
                    "install" -> install(call.argument<String>("path")!!, result)
                    else -> result.notImplemented()
                }
            }
    }

    /** Streams the verified APK into a PackageInstaller session and commits it. */
    private fun install(path: String, result: MethodChannel.Result) {
        val installer = packageManager.packageInstaller
        var sessionId = -1
        try {
            val file = File(path)
            val params = PackageInstaller.SessionParams(
                PackageInstaller.SessionParams.MODE_FULL_INSTALL,
            ).apply {
                setAppPackageName(packageName)
                setSize(file.length())
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED)
                }
            }
            sessionId = installer.createSession(params)
            installer.openSession(sessionId).use { session ->
                file.inputStream().use { input ->
                    session.openWrite("base.apk", 0, file.length()).use { output ->
                        input.copyTo(output)
                        session.fsync(output)
                    }
                }
                // Mutable: the installer fills in EXTRA_STATUS. Explicit
                // intent, as targetSdk 34+ requires for mutable PendingIntents.
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
                val status = PendingIntent.getBroadcast(
                    this,
                    sessionId,
                    Intent(this, InstallStatusReceiver::class.java),
                    flags,
                )
                InstallStatusReceiver.pending?.success(PackageInstaller.STATUS_FAILURE_ABORTED)
                InstallStatusReceiver.pending = result
                session.commit(status.intentSender)
            }
        } catch (e: Exception) {
            if (sessionId != -1) installer.abandonSession(sessionId)
            if (InstallStatusReceiver.pending === result) InstallStatusReceiver.pending = null
            result.success(
                if (e is java.io.IOException) {
                    PackageInstaller.STATUS_FAILURE_STORAGE
                } else {
                    PackageInstaller.STATUS_FAILURE
                },
            )
        }
    }
}
```

There are two reasons for completing an older pending result with `ABORTED`:
- A second install tap (for example after the system dialog was dismissed in a way that sent no status) must not leave the first Dart future hanging.
- It keeps the single `pending` slot honest.

- [ ] **Step 6: Run the test and a build.**
  - `flutter test test/unit/app/android_in_app_update_manifest_test.dart` should pass.
  - `flutter build apk --debug --target-platform android-arm64` should succeed, which shows the Kotlin compiles.
  - `flutter test` should pass in full.

- [ ] **Step 7: Commit.**

```bash
git add android test/unit/app/android_in_app_update_manifest_test.dart
git commit -m "feat(app): install update APKs through a PackageInstaller session"
```

---

### Task 6: l10n strings

**Files:**
- Modify: `l10n/app_en.arb`, `l10n/app_zh_CN.arb`, `l10n/app_zh_TW.arb`
- Modify: `test/unit/l10n/arb_audit_test.dart`

- [ ] **Step 1: Write a failing audit.** Append the following to `_expectedEnKeys` under `// App update check (2026-10)`:

```dart
  // In-app update (2026-10-30)
  // (docs/superpowers/plans/2026-10-30-in-app-apk-update.md Task 6).
  'settingsUpdateConfirmTitle',
  'settingsUpdateConfirmBody',
  'settingsUpdateDownloadAction',
  'settingsUpdateDownloading',
  'settingsUpdateInstall',
  'settingsUpdateInstalling',
  'settingsUpdatePermissionNeeded',
  'settingsUpdateFailedNetwork',
  'settingsUpdateFailedChecksum',
  'settingsUpdateFailedStorage',
  'settingsUpdateFailedSignature',
  'settingsUpdateFailedGeneric',
  'settingsUpdateOpenInBrowser',
```

Run `flutter test test/unit/l10n/arb_audit_test.dart`. It should FAIL.

- [ ] **Step 2: Add the English strings.** Add them to `app_en.arb` after `@settingsNewVersionOpenFailed`, with the existing `}` moved down. Also update the `@settingsNewVersionBadge` description to "…tapping offers to download and install the APK in the app".

```json
  "settingsUpdateConfirmTitle": "Update to {version}?",
  "@settingsUpdateConfirmTitle": { "description": "Title of the dialog shown when the user taps the new-version badge.", "placeholders": { "version": { "type": "String", "example": "v0.7.4" } } },
  "settingsUpdateConfirmBody": "Ledgerly will download about {sizeMb} MB and install the update. Keep Ledgerly open until it finishes. Ledgerly closes while the update installs; open it again afterwards.",
  "@settingsUpdateConfirmBody": { "description": "Body of the update dialog.", "placeholders": { "sizeMb": { "type": "String", "example": "24.4" } } },
  "settingsUpdateDownloadAction": "Download",
  "@settingsUpdateDownloadAction": { "description": "Confirm button of the update dialog." },
  "settingsUpdateDownloading": "downloading {percent}%",
  "@settingsUpdateDownloading": { "description": "Badge label while the update APK downloads.", "placeholders": { "percent": { "type": "int", "example": "42" } } },
  "settingsUpdateInstall": "install",
  "@settingsUpdateInstall": { "description": "Badge label once the update is downloaded and verified; tapping installs it." },
  "settingsUpdateInstalling": "installing…",
  "@settingsUpdateInstalling": { "description": "Badge label while Android installs the update." },
  "settingsUpdatePermissionNeeded": "Allow Ledgerly to install apps, then tap install.",
  "@settingsUpdatePermissionNeeded": { "description": "SnackBar shown when the system 'Install unknown apps' page opens for Ledgerly." },
  "settingsUpdateFailedNetwork": "Download failed. Check your connection and try again.",
  "@settingsUpdateFailedNetwork": { "description": "SnackBar when the update download fails." },
  "settingsUpdateFailedChecksum": "The download was damaged. Try again.",
  "@settingsUpdateFailedChecksum": { "description": "SnackBar when the downloaded APK's SHA-256 does not match the release." },
  "settingsUpdateFailedStorage": "Not enough storage for the update.",
  "@settingsUpdateFailedStorage": { "description": "SnackBar when the APK cannot be saved or installed for lack of space." },
  "settingsUpdateFailedSignature": "This copy of Ledgerly is signed differently from the release, so it cannot update in place.",
  "@settingsUpdateFailedSignature": { "description": "SnackBar when Android rejects the update because the signing key differs (e.g. a debug build)." },
  "settingsUpdateFailedGeneric": "The update could not be installed.",
  "@settingsUpdateFailedGeneric": { "description": "SnackBar for any other install failure." },
  "settingsUpdateOpenInBrowser": "Open in browser",
  "@settingsUpdateOpenInBrowser": { "description": "SnackBar action on update failures: opens the APK download in the system browser." }
```

- [ ] **Step 3: Add the Simplified Chinese strings to `app_zh_CN.arb`.**

```json
  "settingsUpdateConfirmTitle": "更新至 {version}？",
  "settingsUpdateConfirmBody": "Ledgerly 将下载约 {sizeMb} MB 并安装更新。完成前请保持 Ledgerly 开启。安装更新时 Ledgerly 会关闭，之后请重新打开。",
  "settingsUpdateDownloadAction": "下载",
  "settingsUpdateDownloading": "下载中 {percent}%",
  "settingsUpdateInstall": "安装",
  "settingsUpdateInstalling": "安装中…",
  "settingsUpdatePermissionNeeded": "请允许 Ledgerly 安装应用，然后点按「安装」。",
  "settingsUpdateFailedNetwork": "下载失败，请检查网络后重试。",
  "settingsUpdateFailedChecksum": "下载的文件已损坏，请重试。",
  "settingsUpdateFailedStorage": "存储空间不足，无法更新。",
  "settingsUpdateFailedSignature": "此 Ledgerly 的签名与正式版本不同，无法直接更新。",
  "settingsUpdateFailedGeneric": "无法安装更新。",
  "settingsUpdateOpenInBrowser": "在浏览器中打开"
```

- [ ] **Step 4: Add the Traditional Chinese strings to `app_zh_TW.arb`.**

```json
  "settingsUpdateConfirmTitle": "更新至 {version}？",
  "settingsUpdateConfirmBody": "Ledgerly 將下載約 {sizeMb} MB 並安裝更新。完成前請保持 Ledgerly 開啟。安裝更新時 Ledgerly 會關閉，之後請重新開啟。",
  "settingsUpdateDownloadAction": "下載",
  "settingsUpdateDownloading": "下載中 {percent}%",
  "settingsUpdateInstall": "安裝",
  "settingsUpdateInstalling": "安裝中…",
  "settingsUpdatePermissionNeeded": "請允許 Ledgerly 安裝應用程式，然後輕觸「安裝」。",
  "settingsUpdateFailedNetwork": "下載失敗，請檢查網路後重試。",
  "settingsUpdateFailedChecksum": "下載的檔案已損毀，請重試。",
  "settingsUpdateFailedStorage": "儲存空間不足，無法更新。",
  "settingsUpdateFailedSignature": "此 Ledgerly 的簽署與正式版本不同，無法直接更新。",
  "settingsUpdateFailedGeneric": "無法安裝更新。",
  "settingsUpdateOpenInBrowser": "在瀏覽器中開啟"
```

- [ ] **Step 5: Regenerate and run the tests.** Run `flutter gen-l10n`, then `flutter test test/unit/l10n/ test/widget/smoke/`. Both should pass.

- [ ] **Step 6: Commit.**

```bash
git add l10n lib/l10n test/unit/l10n/arb_audit_test.dart
git commit -m "feat(l10n): add in-app update strings"
```

---

### Task 7: `AppUpdateController` and state

**Files:**
- Create: `lib/features/settings/app_update_state.dart`
- Create: `lib/features/settings/app_update_controller.dart`
- Create: `test/unit/controllers/app_update_controller_test.dart`

- [ ] **Step 1: Create the state.** It is pure data, so this is not TDD.

```dart
// In-app update flow state for the Settings new-version badge.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_update_state.freezed.dart';

/// Why the in-app update stopped. Each maps to one SnackBar message.
enum UpdateFailure { network, checksum, storage, signatureConflict, generic }

@freezed
sealed class AppUpdateState with _$AppUpdateState {
  /// Nothing started (or a previous attempt failed and was reported).
  const factory AppUpdateState.idle() = AppUpdateIdle;

  /// Downloading; [percent] is 0–100.
  const factory AppUpdateState.downloading(int percent) = AppUpdateDownloading;

  /// Verified APK at [path]; tapping installs it. [needsPermission] is
  /// true when the "Install unknown apps" page was just opened.
  const factory AppUpdateState.ready(
    String path, {
    @Default(false) bool needsPermission,
  }) = AppUpdateReady;

  /// Handed to Android's installer.
  const factory AppUpdateState.installing(String path) = AppUpdateInstalling;

  /// The last attempt failed; the badge reports it once.
  const factory AppUpdateState.failed(UpdateFailure reason) = AppUpdateFailed;
}
```

- [ ] **Step 2: Write failing controller tests.**

```dart
// Guards AppUpdateController: download → permission → install, progress
// throttling, typed failures, and ignoring taps while downloading.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/bootstrap.dart';
import 'package:ledgerly/app/providers/app_update_provider.dart';
import 'package:ledgerly/data/models/app_update.dart';
import 'package:ledgerly/data/repositories/app_update_repository.dart';
import 'package:ledgerly/features/settings/app_update_controller.dart';
import 'package:ledgerly/features/settings/app_update_state.dart';

class _MockRepo extends Mock implements AppUpdateRepository {}

final _update = AppUpdate(
  version: 'v0.7.4',
  fileName: 'ledgerly-v0.7.4-arm64-v8a.apk',
  apkUrl: Uri.parse('https://example.com/a.apk'),
  sha256: 'ab' * 32,
  sizeBytes: 100,
);
const _path = '/cache/updates/ledgerly-v0.7.4-arm64-v8a.apk';

void main() {
  late _MockRepo repo;
  late ProviderContainer container;
  late List<AppUpdateState> states;

  setUpAll(() => registerFallbackValue(_update));

  setUp(() {
    repo = _MockRepo();
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [appUpdateRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    states = [];
    container.listen(
      appUpdateControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    when(() => repo.canInstall()).thenAnswer((_) async => true);
    when(() => repo.openInstallSettings()).thenAnswer((_) async {});
  });

  AppUpdateController controller() =>
      container.read(appUpdateControllerProvider.notifier);

  void stubDownload({List<double> progress = const []}) {
    when(
      () => repo.download(any(), onProgress: any(named: 'onProgress')),
    ).thenAnswer((inv) async {
      final cb = inv.namedArguments[#onProgress] as void Function(double)?;
      progress.forEach(cb!);
      return _path;
    });
  }

  test('downloads, then installs; progress emits once per whole percent', () async {
    stubDownload(progress: [0.001, 0.004, 0.5, 0.501, 1.0]);
    when(() => repo.install(_path)).thenAnswer((_) => Completer<InstallOutcome>().future);

    unawaited(controller().start(_update));
    await pumpEventQueue();

    expect(states, [
      const AppUpdateState.idle(),
      const AppUpdateState.downloading(0),
      const AppUpdateState.downloading(50),
      const AppUpdateState.downloading(100),
      const AppUpdateState.installing(_path),
    ]);
  });

  test('without install permission opens settings and waits in ready', () async {
    stubDownload();
    when(() => repo.canInstall()).thenAnswer((_) async => false);

    await controller().start(_update);

    expect(states.last, const AppUpdateState.ready(_path, needsPermission: true));
    verify(() => repo.openInstallSettings()).called(1);
    verifyNever(() => repo.install(any()));
  });

  test('tapping again from ready installs without re-downloading', () async {
    stubDownload();
    when(() => repo.canInstall()).thenAnswer((_) async => false);
    await controller().start(_update);
    when(() => repo.canInstall()).thenAnswer((_) async => true);
    when(() => repo.install(_path)).thenAnswer((_) async => InstallOutcome.cancelled);

    await controller().start(_update);

    verify(() => repo.download(any(), onProgress: any(named: 'onProgress'))).called(1);
    expect(states.last, const AppUpdateState.ready(_path));
  });

  test('a tap while downloading is ignored', () async {
    final gate = Completer<String>();
    when(
      () => repo.download(any(), onProgress: any(named: 'onProgress')),
    ).thenAnswer((_) => gate.future);

    unawaited(controller().start(_update));
    await controller().start(_update);

    verify(() => repo.download(any(), onProgress: any(named: 'onProgress'))).called(1);
  });

  for (final (error, reason) in [
    (const UpdateDownloadException(), UpdateFailure.network),
    (const UpdateChecksumException(), UpdateFailure.checksum),
    (const UpdateStorageException(), UpdateFailure.storage),
  ]) {
    test('${error.runtimeType} fails with $reason', () async {
      when(
        () => repo.download(any(), onProgress: any(named: 'onProgress')),
      ).thenThrow(error);
      await controller().start(_update);
      expect(states.last, AppUpdateState.failed(reason));
    });
  }

  for (final (outcome, expected) in [
    (InstallOutcome.cancelled, const AppUpdateState.ready(_path)),
    (InstallOutcome.signatureConflict, const AppUpdateState.failed(UpdateFailure.signatureConflict)),
    (InstallOutcome.storage, const AppUpdateState.failed(UpdateFailure.storage)),
    (InstallOutcome.failed, const AppUpdateState.failed(UpdateFailure.generic)),
  ]) {
    test('install $outcome → $expected', () async {
      stubDownload();
      when(() => repo.install(_path)).thenAnswer((_) async => outcome);
      await controller().start(_update);
      expect(states.last, expected);
    });
  }

  test('after a failure, a tap starts over', () async {
    when(
      () => repo.download(any(), onProgress: any(named: 'onProgress')),
    ).thenThrow(const UpdateDownloadException());
    await controller().start(_update);
    stubDownload();
    when(() => repo.install(_path)).thenAnswer((_) async => InstallOutcome.cancelled);

    await controller().start(_update);

    expect(states.last, const AppUpdateState.ready(_path));
  });
}
```

- [ ] **Step 3: Run the tests and watch them fail.** Run `flutter test test/unit/controllers/app_update_controller_test.dart`.

- [ ] **Step 4: Implement the controller.**

```dart
// In-app update controller (docs/superpowers/plans/2026-10-30-in-app-apk-update.md).
//
// Keep-alive (not a family, so allowed) so a download keeps going when
// the user leaves Settings. build() has no side effects; every await is
// followed by a ref.mounted check.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/app_update_provider.dart';
import '../../data/models/app_update.dart';
import '../../data/repositories/app_update_repository.dart';
import 'app_update_state.dart';

part 'app_update_controller.g.dart';

@Riverpod(keepAlive: true)
class AppUpdateController extends _$AppUpdateController {
  @override
  AppUpdateState build() => const AppUpdateState.idle();

  /// The badge tap: downloads and verifies [update] if needed, then
  /// installs it. Ignored while a download is running.
  Future<void> start(AppUpdate update) async {
    final repo = ref.read(appUpdateRepositoryProvider);
    switch (state) {
      case AppUpdateDownloading():
        return;
      case AppUpdateReady(:final path) || AppUpdateInstalling(:final path):
        return _install(repo, path);
      case AppUpdateIdle() || AppUpdateFailed():
        state = const AppUpdateState.downloading(0);
        final String path;
        try {
          path = await repo.download(update, onProgress: _onProgress);
        } on UpdateChecksumException {
          return _fail(UpdateFailure.checksum);
        } on UpdateStorageException {
          return _fail(UpdateFailure.storage);
        } on Object {
          return _fail(UpdateFailure.network);
        }
        if (!ref.mounted) return;
        return _install(repo, path);
    }
  }

  void _onProgress(double fraction) {
    final percent = (fraction * 100).floor().clamp(0, 100);
    if (!ref.mounted) return;
    if (state case AppUpdateDownloading(percent: final p) when p != percent) {
      state = AppUpdateState.downloading(percent);
    }
  }

  Future<void> _install(AppUpdateRepository repo, String path) async {
    if (!await repo.canInstall()) {
      if (!ref.mounted) return;
      state = AppUpdateState.ready(path, needsPermission: true);
      await repo.openInstallSettings();
      return;
    }
    if (!ref.mounted) return;
    state = AppUpdateState.installing(path);
    final outcome = await repo.install(path);
    if (!ref.mounted) return;
    state = switch (outcome) {
      // Android replaces this process; nothing left to show.
      InstallOutcome.success => AppUpdateState.installing(path),
      InstallOutcome.cancelled => AppUpdateState.ready(path),
      InstallOutcome.signatureConflict =>
        const AppUpdateState.failed(UpdateFailure.signatureConflict),
      InstallOutcome.storage => const AppUpdateState.failed(UpdateFailure.storage),
      InstallOutcome.failed => const AppUpdateState.failed(UpdateFailure.generic),
    };
  }

  void _fail(UpdateFailure reason) {
    if (ref.mounted) state = AppUpdateState.failed(reason);
  }
}
```

A tap in `installing` re-runs the install, rather than being ignored. If the system confirm dialog was dismissed without a status (for example, the background-launch block on some Android 14 builds), the badge would otherwise be stuck on "installing…". The Kotlin side completes the older pending result with `ABORTED`, so nothing hangs.

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 5: Run the tests.** `flutter test test/unit/controllers/app_update_controller_test.dart test/unit/architecture/` should pass. Then run `dart analyze --fatal-infos`. riverpod_lint may require a `dependencies:` annotation: if it reports `scoped_providers_should_specify_dependencies`, mirror `appUpdateRepositoryProvider`, which declares none.

- [ ] **Step 6: Commit.**

```bash
git add lib/features/settings/app_update_state.dart lib/features/settings/app_update_state.freezed.dart lib/features/settings/app_update_controller.dart lib/features/settings/app_update_controller.g.dart test/unit/controllers/app_update_controller_test.dart
git commit -m "feat(settings): add the in-app update controller"
```

---

### Task 8: Badge drives the in-app update

**Files:**
- Modify: `lib/features/settings/widgets/new_version_badge.dart`
- Modify: `test/widget/features/settings/new_version_badge_test.dart`

The widget tests wrap the badge in a `ProviderScope` and override `appUpdateControllerProvider` with a fake notifier class. The fake records `start` calls and lets the test set `state`.

```dart
class _FakeController extends AppUpdateController {
  _FakeController(this.initial);
  final AppUpdateState initial;
  final started = <AppUpdate>[];
  @override
  AppUpdateState build() => initial;
  @override
  Future<void> start(AppUpdate update) async => started.add(update);
  void emit(AppUpdateState s) => state = s;
}
```

`_wrap` becomes:

```dart
Widget _wrap(Widget child, {ThemeData? theme, _FakeController? controller}) =>
    ProviderScope(
      overrides: [
        appUpdateControllerProvider.overrideWith(
          () => controller ?? _FakeController(const AppUpdateState.idle()),
        ),
      ],
      child: MaterialApp(/* unchanged */),
    );
```

Fixtures:
- `_inApp` is an `AppUpdate` with `sha256: 'ab' * 32`, `sizeBytes: 25568852` and `version: 'v0.7.4'`.
- `_browserOnly` is the same update with no sha256 or size.

- [ ] **Step 1: Write failing tests.** Keep the existing NVB01–05. NVB02/03 now use `_browserOnly`, so the browser path stays covered. Add:

```dart
  testWidgets('NVB06: in-app update asks first, then starts on Download', (tester) async {
    final c = _FakeController(const AppUpdateState.idle());
    await tester.pumpWidget(_wrap(NewVersionBadge(update: _inApp), controller: c));
    await tester.tap(find.text('new version'));
    await tester.pumpAndSettle();

    expect(find.text('Update to v0.7.4?'), findsOneWidget);
    expect(find.textContaining('about 24.4 MB'), findsOneWidget);
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(c.started, [_inApp]);
  });

  testWidgets('NVB07: cancelling the dialog does not start', (tester) async {
    final c = _FakeController(const AppUpdateState.idle());
    await tester.pumpWidget(_wrap(NewVersionBadge(update: _inApp), controller: c));
    await tester.tap(find.text('new version'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(c.started, isEmpty);
  });

  testWidgets('NVB08: labels follow the controller state', (tester) async {
    final c = _FakeController(const AppUpdateState.downloading(42));
    await tester.pumpWidget(_wrap(NewVersionBadge(update: _inApp), controller: c));
    expect(find.text('downloading 42%'), findsOneWidget);
    c.emit(const AppUpdateState.ready('/a.apk'));
    await tester.pump();
    expect(find.text('install'), findsOneWidget);
    c.emit(const AppUpdateState.installing('/a.apk'));
    await tester.pump();
    expect(find.text('installing…'), findsOneWidget);
  });

  testWidgets('NVB09: tapping install starts without a dialog', (tester) async {
    final c = _FakeController(const AppUpdateState.ready('/a.apk'));
    await tester.pumpWidget(_wrap(NewVersionBadge(update: _inApp), controller: c));
    await tester.tap(find.text('install'));
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(c.started, [_inApp]);
  });

  testWidgets('NVB10: permission prompt shows a SnackBar', (tester) async {
    final c = _FakeController(const AppUpdateState.downloading(100));
    await tester.pumpWidget(_wrap(NewVersionBadge(update: _inApp), controller: c));
    c.emit(const AppUpdateState.ready('/a.apk', needsPermission: true));
    await tester.pump();
    expect(find.text('Allow Ledgerly to install apps, then tap install.'), findsOneWidget);
  });

  testWidgets('NVB11: a failure shows its message with an Open in browser action', (tester) async {
    final calls = <Uri>[];
    final c = _FakeController(const AppUpdateState.downloading(3));
    await tester.pumpWidget(_wrap(
      NewVersionBadge(
        update: _inApp,
        launch: (url, {mode = LaunchMode.platformDefault}) async {
          calls.add(url);
          return true;
        },
      ),
      controller: c,
    ));
    c.emit(const AppUpdateState.failed(UpdateFailure.signatureConflict));
    await tester.pump();
    expect(find.textContaining('signed differently'), findsOneWidget);
    await tester.tap(find.text('Open in browser'));
    await tester.pump();
    expect(calls, [_inApp.apkUrl]);
    // A failed attempt shows the idle label again, so the next tap retries.
    expect(find.text('new version'), findsOneWidget);
  });

  testWidgets('NVB12: progress label survives 2x text scale', (tester) async {
    final c = _FakeController(const AppUpdateState.downloading(100));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_wrap(NewVersionBadge(update: _inApp), controller: c));
    expect(tester.takeException(), isNull);
  });
```

- [ ] **Step 2: Run the tests and watch them fail.** Run `flutter test test/widget/features/settings/new_version_badge_test.dart`.

- [ ] **Step 3: Implement.** The badge becomes a `ConsumerWidget`. The existing style and `_labelColorOn` are unchanged.

```dart
// Pink "new version" pill shown beside the app version at the bottom of
// Settings when a newer GitHub release exists. When the release publishes
// a SHA-256, tapping downloads, verifies and installs the APK in the app
// (AppUpdateController); otherwise, and as the fallback on every failure,
// it opens the APK URL in the system browser.

class NewVersionBadge extends ConsumerWidget {
  const NewVersionBadge({
    super.key,
    required this.update,
    @visibleForTesting this.launch = launchUrl,
  });

  final AppUpdate update;
  final LaunchUrlFn launch;

  Future<void> _openInBrowser(ScaffoldMessengerState? messenger, String failed) async {
    final launched = await openInSystemBrowser(update.apkUrl, launch: launch);
    if (!launched) messenger?.showSnackBar(SnackBar(content: Text(failed)));
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, AppUpdateState state) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final sizeBytes = update.sizeBytes;
    if (update.sha256 == null || sizeBytes == null) {
      return _openInBrowser(messenger, l10n.settingsNewVersionOpenFailed);
    }
    final controller = ref.read(appUpdateControllerProvider.notifier);
    if (state is AppUpdateIdle || state is AppUpdateFailed) {
      final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.settingsUpdateConfirmTitle(update.version)),
          content: Text(l10n.settingsUpdateConfirmBody(sizeMb)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.settingsUpdateDownloadAction),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await controller.start(update);
  }

  void _report(BuildContext context, AppUpdateState next) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final message = switch (next) {
      AppUpdateReady(needsPermission: true) => l10n.settingsUpdatePermissionNeeded,
      AppUpdateFailed(:final reason) => switch (reason) {
        UpdateFailure.network => l10n.settingsUpdateFailedNetwork,
        UpdateFailure.checksum => l10n.settingsUpdateFailedChecksum,
        UpdateFailure.storage => l10n.settingsUpdateFailedStorage,
        UpdateFailure.signatureConflict => l10n.settingsUpdateFailedSignature,
        UpdateFailure.generic => l10n.settingsUpdateFailedGeneric,
      },
      _ => null,
    };
    if (message == null) return;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        action: next is AppUpdateFailed
            ? SnackBarAction(
                label: l10n.settingsUpdateOpenInBrowser,
                onPressed: () => _openInBrowser(messenger, l10n.settingsNewVersionOpenFailed),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appUpdateControllerProvider);
    ref.listen(appUpdateControllerProvider, (previous, next) {
      if (previous != next) _report(context, next);
    });
    final label = switch (state) {
      AppUpdateDownloading(:final percent) => l10n.settingsUpdateDownloading(percent),
      AppUpdateReady() => l10n.settingsUpdateInstall,
      AppUpdateInstalling() => l10n.settingsUpdateInstalling,
      AppUpdateIdle() || AppUpdateFailed() => l10n.settingsNewVersionBadge,
    };
    final fill = Theme.of(context).colorScheme.primary;
    return FilledButton(
      key: const ValueKey('settingsNewVersionBadge'),
      style: /* unchanged */,
      onPressed: () => _onTap(context, ref, state),
      child: Text(label),
    );
  }
}
```

Imports:
- `flutter_riverpod`
- `../../../data/models/app_update.dart`
- `../app_update_controller.dart`
- `../app_update_state.dart`

The layer rule `widget_helpers_forbid_data_internals` allows models and controllers.

The `settings_screen_test` fixture also needs `sha256: null`. That is already the default, so the badge test there still checks the browser URL, and the screen tests need no controller override: the real `AppUpdateController` builds to idle without I/O.

- [ ] **Step 4: Run the tests.** `flutter test` should pass in full. `flutter test test/unit/architecture/` and `dart analyze --fatal-infos` should be clean.

- [ ] **Step 5: Commit.**

```bash
git add lib/features/settings/widgets/new_version_badge.dart test/widget/features/settings/new_version_badge_test.dart
git commit -m "feat(settings): download and install updates from the new-version badge"
```

---

### Task 9: Docs

**Files:**
- Modify: `docs/architecture/bootstrap.md`, the paragraph at line 14. Append: "`checkAfter` then deletes stale files under `<cacheDir>/updates/`, keeping only the found release's verified APK. The download and install happen only on a badge tap (`AppUpdateController`)."
- Modify: `docs/architecture/testing.md`. Add the new tests to the settings and app-update rows of the per-slice coverage map: `apk_installer_service_test`, `app_update_controller_test`, `android_in_app_update_manifest_test`, and the extended repository and badge tests.
- Modify: `README.md`, only if it describes the update badge as opening the browser (check with `grep -n "new version\|browser" README.md`).

- [ ] **Step 1: Make the edits, then run `flutter test test/unit/architecture/`.**
- [ ] **Step 2: Commit.**

```bash
git add docs README.md
git commit -m "docs: describe the in-app update flow"
```

---

### Task 10: Manual device verification (no Kotlin test harness)

This is required before the PR is merged, and the results are reported in the PR description. Build two release-signed APKs locally with the release keystore: vN (the current `pubspec.yaml` version) and vN+1. The badge needs a GitHub release newer than the installed version, so point the check at a real newer release by installing an APK whose `pubspec.yaml` version is set one patch below the latest GitHub release.

- [ ] On Android 14 or 15:
  - the first tap opens "Install unknown apps";
  - after granting, "install" completes **with no confirm dialog**;
  - the app closes, and on reopening the version is updated and `cacheDir/updates/` is empty.
- [ ] On Android 11, if available: granting the permission kills the app. After reopening, the badge shows "new version"; tapping and confirming reuses the verified file (no second download), then the confirm dialog shows and the install completes.
- [ ] Cancel the system confirm dialog where it appears: the badge returns to "install".
- [ ] On a debug build (`flutter run`), the update fails with the "signed differently" SnackBar, and "Open in browser" opens the APK URL.
- [ ] Airplane mode mid-download gives the network SnackBar; tapping again restarts the download.

---

## Self-review notes

- **Spec coverage:** every decision has a task:
  - download in-app with progress (Tasks 1, 4, 7, 8);
  - SHA-256 in Dart with `crypto` (Task 4);
  - PackageInstaller install, permission flow and prompt-free 12+ (Task 5);
  - browser fallback on every failure (Task 8);
  - foreground-only (no service anywhere);
  - stale-file clean-up (Task 4);
  - l10n (Task 6).
- **Types:**
  - `ReleaseAsset` (Task 1) is used in Task 3.
  - `AppUpdate` (Task 3) is used in Tasks 4, 7 and 8.
  - `InstallOutcome` and the `Update*Exception` classes (Task 4) are used in Task 7.
  - `AppUpdateState`/`UpdateFailure` (Task 7) are used in Task 8.
- **Commit independence:** Task 3 is the single cross-layer commit (type change), and its commit body says so. Each other task compiles and tests on its own.
