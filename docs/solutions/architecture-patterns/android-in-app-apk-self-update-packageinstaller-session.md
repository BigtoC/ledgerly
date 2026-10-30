---
title: In-app APK self-update through a PackageInstaller session over a custom MethodChannel
date: 2026-10-30
category: architecture-patterns
module: settings
problem_type: architecture_pattern
component: service_object
severity: medium
applies_when:
  - "An Android app shipped outside Google Play (GitHub Releases, sideload) must download and install its own updates in-app"
  - "A third-party OTA plugin would add permissions, a second HTTP stack, a FileProvider or release logging of exception messages"
  - "A Flutter MethodChannel hands work to Android system UI and the result comes back later through a BroadcastReceiver"
  - "A MethodChannel handler does blocking I/O on Flutter 3.29+, where the Android platform and UI threads are merged"
  - "A user can tap again while an earlier native call is still pending, so a superseded result can arrive after a newer attempt"
  - "A downloaded release artifact must be integrity-checked before use"
symptoms:
  - "The Settings new-version pill opened the APK URL in the system browser, so every update was downloaded and installed by hand"
  - "Copying the APK into the PackageInstaller session inside the MethodChannel handler froze the Flutter UI"
  - "Re-tapping while installing reset the badge to install mid-install because the first call's ABORTED result was read as cancelled"
resolution_type: code_fix
related_components:
  - app_release_service
  - apk_installer_service
  - app_update_repository
  - app_update_controller
  - new_version_badge
  - main_activity_kt
  - install_status_receiver_kt
tags:
  - android
  - in-app-update
  - packageinstaller
  - method-channel
  - apk
  - sha256-digest
  - github-releases
  - riverpod
---

# In-app APK self-update through a PackageInstaller session over a custom MethodChannel

## Context

Ledgerly ships split per-ABI, release-signed APKs only through GitHub Releases. PR #57 added an update check. When a newer release existed, the Settings "new version" pill opened the APK URL in the system browser, and the user downloaded and installed the update by hand. PR #63 replaced that with an in-app flow: download the APK, verify it, then hand it to the Android installer. On Android 12+ the install needs no confirm prompt.

Rejected options:
- **`ACTION_VIEW` + FileProvider.** It returns no status codes and can never skip the prompt. `ACTION_INSTALL_PACKAGE` has been deprecated since API 29.
- **`ota_update` 7.1.0.**
  - Its PackageInstaller mode is opt-in, and the bug fixes for that mode had not been released.
  - It merges `WRITE_EXTERNAL_STORAGE`, `INSTALL_PACKAGES`, `ACCESS_WIFI_STATE` and `ACCESS_NETWORK_STATE` into the manifest.
  - It bundles OkHttp and commons-codec, and forces core-library desugaring.
  - It needs a FileProvider.
  - It calls `Log.d/e(e.getMessage())` in release builds, which breaks the repo's rule that logs carry the exception type only.
- **`flutter_app_update`.** It brings its own download service, notifications and dialog.

The choice: about 150 lines of our own Kotlin behind a `ledgerly/apk_installer` channel. The SHA-256 check is in Dart (`crypto`), and the download runs only while the app is in the foreground.

## Guidance

**Dart layers**

| Layer | File | Responsibility |
|---|---|---|
| Service | `lib/data/services/app_release_service.dart` | Parses each asset's `digest` (`"sha256:<hex>"`) and `size` from the GitHub release JSON, so there is no `checksums.txt` to parse. Downloads with `dio.downloadUri(..., deleteOnError: true)`. |
| Service | `lib/data/services/apk_installer_service.dart` | A thin `const` channel wrapper: `canRequestInstalls`, `openInstallSettings`, and `install(path) → int` (a `PackageInstaller.STATUS_*` code). |
| Repository | `lib/data/repositories/app_update_repository.dart` | See the list below. |
| Controller | `lib/features/settings/app_update_controller.dart` | `keepAlive` and not a family, so a download survives leaving Settings. State goes `idle → downloading(percent) → ready(path, needsPermission) → installing(path)`, or `failed(UpdateFailure)`. |
| Widget | `lib/features/settings/widgets/new_version_badge.dart` | Shows the confirm dialog and the progress label. Every failure SnackBar has an "Open in browser" action. |

The repository does the following:
- **`findUpdate()`** sets `sha256` and `sizeBytes` only when both are valid. When they aren't, the badge **fails closed** to the browser.
- **`download()`** writes `<cache>/updates/<name>.part`, checks the SHA-256, then renames the file. It reuses a file it already verified.
- **`cleanUp(keep:)`** runs on every launch.
- **Errors** are typed: `Update{Download,Checksum,Storage}Exception`.

**Android pieces**

*Manifest:*
- `REQUEST_INSTALL_PACKAGES`, required on target 26+.
- `UPDATE_PACKAGES_WITHOUT_USER_ACTION`, a normal permission.
- `<receiver android:name=".InstallStatusReceiver" android:exported="false"/>`.

*The "Install unknown apps" toggle:*
- Check it with `packageManager.canRequestPackageInstalls()`.
- Open it with `Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES` plus `package:<id>`.
- **Android 11 kills the app when the user flips the toggle.** Keep the verified APK so the next tap reuses it.

*The install session:*
- **Session params:** `setAppPackageName` and `setSize`. On API 31+, also `setRequireUserAction(USER_ACTION_NOT_REQUIRED)`, which makes the self-update prompt-free. Android may still ask, so always handle `STATUS_PENDING_USER_ACTION` (-1) by starting `Intent.EXTRA_INTENT`.
- **`commit()` intent:** a **mutable** `PendingIntent` (required on target 35+) wrapping an **explicit** intent to the receiver (required on target 34+).
- **Success kills the process, so the Dart `install` future never completes on success.** Don't build UI that waits for it.

The repository maps status codes to `InstallOutcome`:

| Status code | `InstallOutcome` |
|---|---|
| 0 | `success` |
| 3 (ABORTED) | `cancelled` |
| 5 (CONFLICT: a different signing key, for example a debug build) | `signatureConflict` |
| 6 | `storage` |
| anything else | `failed` |

### Pitfalls the reviews caught (all fixed in #63)

1. **The typed `Intent.getParcelableExtra(name, Class)` is buggy on API 33.** An exception in `onReceive` breaks the confirm path. Use the typed overload only when `SDK_INT >= UPSIDE_DOWN_CAKE` (34), which is the same cutoff AndroidX `IntentCompat` uses, and the deprecated untyped one below that.
2. **Blocking I/O inside a MethodChannel handler freezes the UI.** Since Flutter 3.29 the Android platform and UI threads are the same thread. The ~25 MB copy and `fsync` now run on a background `Thread`, and `runOnUiThread { commit(...) }` follows. The receiver also runs on the main thread, so `pending` is set before any status can arrive, and the `Result` completes exactly once.
3. **A superseded call's result overwrote newer state.** Re-tapping while "installing…" is allowed on purpose, because it relaunches a blocked confirm dialog. Kotlin then completed the first pending `Result` with ABORTED. The first Dart `_install` read that as `cancelled` and set `ready` mid-install. **Guard both sides:**
   - **Dart:** an attempt counter, `stale() => !ref.mounted || attempt != _installAttempt`, ignores superseded results. This is the same generation-token idea as the analysis drill-down (see Related).
   - **Kotlin:** track `pendingSessionId`. Quietly abandon the replaced session; Android ignores the abandon once the user has confirmed. In the receiver, drop any status whose `EXTRA_SESSION_ID != pendingSessionId`. Without that drop, the late ABORTED that the abandon itself sends brings the bug back.
4. **A native helper that throws can leave the state machine stuck.** `canInstall()` throwing left the state at `downloading`, and `openInstallSettings()` throwing escaped `onPressed`. Catch both and move to `failed(generic)`, behind `stale()`.
5. **dio wraps disk-full errors.** They arrive as `DioException(error: FileSystemException)` and looked like network failures. Unwrap `e.error` and throw the storage exception.

## Why This Matters

- **A PackageInstaller session streams a file the app already has.** It needs no FileProvider and no storage permission. It returns real status codes, so the app can show distinct messages for signature conflict, storage and cancel. It is also the only route to a prompt-free self-update.
- **Checking against GitHub's own asset `digest` and failing closed to the browser** means an unverified APK never reaches the installer. Android's same-signing-key rule remains the trust anchor for authenticity.
- **Pitfalls 2 and 3 apply to any channel that hands work to system UI** and gets the answer later: blocking the UI thread, completing a `Result` twice or never, or letting a stale callback win. They are easy to miss because unit tests can't see the Kotlin side.

## When to Apply

- An Android app distributed outside Play wants in-app updates.
- A MethodChannel call is answered later by system UI (an installer, a permission page, a picker), or can be tapped again while it is still pending. See Pitfalls 2 and 3.

## Examples

Kotlin: copy off the main thread, then commit on it (`android/app/src/main/kotlin/com/example/ledgerly/MainActivity.kt`):

```kotlin
Thread {
    sessionId = installer.createSession(params)
    // Copy file.inputStream() into session.openWrite("base.apk", ...), then session.fsync(output).
    val flags = PendingIntent.FLAG_UPDATE_CURRENT or
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
    val status = PendingIntent.getBroadcast(
        this, sessionId, Intent(this, InstallStatusReceiver::class.java), flags,
    )
    val written = sessionId
    runOnUiThread { commit(installer, written, status, result) }
}.start()

// commit(), on the main thread: a newer tap replaces the install in flight.
val replaced = InstallStatusReceiver.pendingSessionId
InstallStatusReceiver.finish(PackageInstaller.STATUS_FAILURE_ABORTED)
if (replaced != -1) abandonQuietly(installer, replaced)
InstallStatusReceiver.pending = result
InstallStatusReceiver.pendingSessionId = sessionId
installer.openSession(sessionId).use { it.commit(status.intentSender) }
```

Receiver: drop stale sessions, and use typed extras only on 34+ (`InstallStatusReceiver.kt`):

```kotlin
if (intent.getIntExtra(PackageInstaller.EXTRA_SESSION_ID, -1) != pendingSessionId) return
if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
    val confirm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
        intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
    } else {
        @Suppress("DEPRECATION")
        intent.getParcelableExtra(Intent.EXTRA_INTENT)
    }
    // start `confirm` with FLAG_ACTIVITY_NEW_TASK; the final status arrives later
}
```

Dart: ignore superseded installs (`app_update_controller.dart`):

```dart
final attempt = ++_installAttempt;
bool stale() => !ref.mounted || attempt != _installAttempt;
// ...
final outcome = await repo.install(path);
if (stale()) return;
```

### Testing without a Kotlin harness

- **Channel:** mock it with `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler` and check method names, arguments and how null results decode.
- **Repository:** test against a temp `Directory` with a fake download that writes known bytes. Cover:
  - a checksum mismatch deletes the `.part` file;
  - an already-verified file is reused without downloading;
  - a dio-wrapped `FileSystemException` maps to a storage failure;
  - the full status-code mapping.
- **Controller:** use a mocked repository. Cover the re-tap mid-install race, the native helpers throwing, and progress throttled to whole-percent changes.
- **Harness friction:**
  - `riverpod_lint`'s `scoped_providers_should_specify_dependencies` forces widget tests to use `ProviderContainer` + `UncontrolledProviderScope` instead of `ProviderScope(overrides:)`.
  - A SnackBar action is only hit-testable after `pumpAndSettle`.
- **Kotlin:** `test/unit/app/android_in_app_update_manifest_test.dart` reads the manifest and `MainActivity.kt` as text and asserts the two permissions, `exported="false"` and the channel name. `flutter build apk --debug` proves the Kotlin compiles.
- **Device checks.** Behaviour only a device shows goes in a manual checklist (plan Task 10):
  - prompt-free on 12+ from a copy installed through the browser;
  - the Android 11 kill when the toggle flips;
  - cancelling the confirm dialog;
  - CONFLICT on a debug build;
  - airplane mode during the download.

**Known limits:**
- The first release that ships this still has to be installed through the browser.
- Android 10+ can block the confirm activity from the background; a re-tap relaunches it.

## Related

- **The work itself:** PR #63 (merge `4a44485`), with the predecessor PR #57 (the update check plus the browser badge). Plan: `docs/superpowers/plans/2026-10-30-in-app-apk-update.md`.
- **Living flow docs:** `docs/architecture/bootstrap.md` (the flow after the first frame) and `docs/architecture/testing.md` (the app-update test map).
- `docs/solutions/logic-errors/analysis-slice-drilldown-delete-guards-fx-alignment-2026-05-22.md`: the `_generation` token guard that `_installAttempt` repeats on the Dart side.
- `docs/solutions/performance-issues/flutter-performance-audit-riverpod-lifecycle-and-emit-path-fixes.md`: the `runtimeType`-only logging rule (the reason `ota_update` was rejected), `keepAlive` only on non-family providers, and SnackBars with actions persisting by default.
- `docs/solutions/runtime-errors/riverpod-cross-provider-dependencies-assertion-2026-05-10.md`: background on scoped-provider dependencies (the harness friction note).
