# Google Drive Cloud Backup — Design Spec

**Date:** 2026-11-23
**Status:** Ready for review. The user decided the product questions on 2026-11-19 (see [Decisions](#decisions)). On 2026-11-23 the user approved every deviation from PRD and every decision this spec made, except an account-wide Disconnect through Google's revoke endpoint, which the user rejected. Disconnect now affects only this device, so the connected account's email is stored per device: D-16 is replaced and D-19 changes with it. After the document review the same day, the user also approved D-26 (an overdue subtitle on the Settings tile) and the 20-hour Daily threshold. The user also added a use case on 2026-11-23: after Connect on a new phone, the app offers to restore an existing Drive backup (D-25). Three defaults were chosen without asking and stay revisitable. This spec changes one of them; see [Deviations from PRD](#deviations-from-prd). The [Prerequisites](#prerequisites) gate the build: S2 runs after commit 4, and S1 and S3 after commit 6, each before the next commit starts. A second document review on 2026-11-23 fixed the invalid snippets, the dependency propagation lists, D-15's cross-device restore identity and the PRD/decision gaps; the deviation list and commit plan below include those fixes.
**PRD reference:** `PRD.md` § Cloud Backup (Phase 3 — not yet implemented); § Roadmap Phase 3 "[Pending] Cloud backup"; § Bootstrap Sequence (the note after step 8); § user_preferences "Cloud backup keys"; § Security & Privacy "Cloud backup (Phase 3, decided 2026-11-19)"; § Dependencies → Deferred `google_sign_in`. `PRD.md:N` line numbers refer to PRD.md at 7b1540f6, before commit 1 edits it; later commits find each line by the text quoted or described next to it.
**Issue:** [#157](https://github.com/BigtoC/ledgerly/issues/157) "Problem: No cloud backup"

---

## Summary

Add **Settings → Data Management → Google Drive backup**. The user connects their own Google account, which grants the `drive.appdata` scope (plus the basic profile Google Sign-In always returns). The device stores that account's email. The app then backs up the whole SQLite database to that account's hidden Drive `appDataFolder`, on a tap or automatically (Off, Daily or Weekly) while the app is open. Each device keeps exactly one backup in Drive. Disconnect affects only this device. Restore runs only from the Backup screen: it downloads a backup, checks it, stages it next to the database, and restarts the app in-process on the restored file. Right after Connect, the screen offers the account's newest backup when it is newer than this device's last backup, so a new phone can start from the old phone's data.

There is no schema change. The work needs:

- one package, `google_sign_in` 7.x;
- three new services (database file paths, Google auth, Drive REST), one new repository and four new `user_preferences` keys;
- one restart path through `bootstrapFor`, because nothing closes `AppDatabase` today.

**Acceptance criteria:**

1. On a fresh install, startup makes no `google_sign_in` call, `backup_frequency` reads `off`, `backup_account_email` reads null, and the Backup screen shows "Connect Google account" without calling `google_sign_in`.
2. After Connect to an account with no backups, `backup_account_email` holds the picked account's email, no restore offer appears, and the screen shows that email and "There are no backups in this Google account yet."
3. "Back up now" leaves exactly one file for this device in `appDataFolder` with the five `appProperties` in [Drive file format](#drive-file-format), and the screen shows "Last backup: <date, time> · <size> MB". A second "Back up now" still leaves exactly one file for this device: the new one is uploaded and checked before the old one is deleted.
4. Two devices on one account each list both backups. Neither ever deletes the other's (both devices on the same platform if S1 fails).
5. Restore (after the confirm) shows "Restoring…", then the app restarts in the same process and Home shows the backup's transactions. Theme, locale, splash settings and default currency come from the backup. This device's `backup_account_email` is unchanged, and its `device_id` is unchanged when the backup came from this device (restoring another device's backup writes a new one, so this device cannot prune that device's file); `backup_frequency` is this device's if it has ever set one, otherwise the backup's; `last_backup_at` becomes the restore time, so no automatic backup runs for one period after a restore. Nothing in Drive changes. A device on another platform lists only its own platform's backups if S1 fails.
6. If the process dies after the restore is staged, the next cold start opens the restored data.
7. A backup whose `schema_version` is above the app's `schemaVersion` shows "Update Ledgerly to restore this backup" and has no Restore action.
8. "Back up now" while offline, while the SDK's cached access token is still valid (up to an hour after it was issued), shows "No internet connection. Try again when you're online." Offline after that, it shows the generic error (see S3-f). Drive is unchanged either way.
9. With Daily on and a last backup at least 20 hours old, a launch runs exactly one automatic backup after the first frame. Coming back from the background when a backup is due runs one. Pulling down the notification shade runs none. Writing `last_backup_at` starts none.
10. Disconnect makes no network request. It signs out on this device, clears `backup_account_email`, sets `backup_frequency` to `off`, and the screen shows "Connect Google account". The backups stay in Drive, and Ledgerly stays in the Google account's third-party connections. On Android the next Connect shows the account picker again; on iOS Google's sign-in page decides whether to show its chooser (S3-c).
11. The Backup screen has no overflow at 2× text scale, at 390 and at 1000 wide.
12. A release-signed Android APK and an iOS build connect, back up and restore against the In-production consent screen, and `ios-nightly.yml` passes without creating a Podfile.
13. After Disconnect on one device, a second device connected to the same account keeps backing up, by tap and automatically, and its list still shows the first device's backup.
14. On a new phone (a fresh install), Connect to an account whose newest backup is restorable asks "Restore from Google Drive?" with that backup's date, platform and app version. Restore replaces the data as in criterion 5. Cancel changes nothing, and the backup stays in the list. No offer appears when the account's newest backup is not restorable, or is not newer than this device's `last_backup_at`, or when this device has never backed up but already holds transactions.
15. With Daily on, the Settings tile shows "Last backup 3 days ago" when this device's last backup is 3 days old, "This device has no backup yet." when it has none, and no subtitle when the last backup is under 48 hours old or automatic backup is Off.

---

## Goals

- Opt-in backup of the whole database to the user's own Drive `appDataFolder`, Off by default.
- One backup per device: upload, check, then delete this device's previous backup. Never delete another device's.
- "Back up now", plus Daily or Weekly automatic backups while the app is open.
- A list of every backup in the account (this device's and other devices'), with Restore and Delete.
- After Connect, an offer to restore the account's newest backup when it is newer than this device's last backup.
- An all-or-nothing restore that survives a process death after staging.
- A Disconnect that affects only this device.
- No OAuth token stored by the app, and no financial data in logs or in Drive metadata.

## Non-goals

- **Sync or merge.** A restore replaces all local data. Only `transactions` has a `uuid`, and deletes are hard deletes (PRD).
- **Encryption.** Decided by the user; the screen says the backup is unencrypted.
- **Older generations.** Drive holds one backup per device. A backup taken after an accidental delete replaces the good one.
- **Background backups.** No `workmanager` (PRD § Automatic backup).
- **Restore during first run or onboarding.** Restore only from Settings.
- **An in-app full revoke.** Disconnect is local (D-16). The Google Account's third-party connections page removes Ledgerly's access on every device.
- **iCloud, Firebase, Supabase or a Ledgerly server.**
- **Wi-Fi-only or cellular settings, upload progress, resuming an interrupted upload, retries with backoff.** The next due check or a tap is the retry.
- **Changing the app id** (`com.example.ledgerly` stays) or turning off Android Auto Backup / iOS device backup.
- **A Play App Signing OAuth client.** Releases ship through GitHub Releases today (PRD § Google Cloud Setup).

---

## Prerequisites

### P1 — Google Cloud project, consent screen and OAuth clients (one-time)

Follow `PRD.md` § Google Cloud Setup:

- One Cloud project with the Drive API enabled.
- OAuth consent screen: External, scope `drive.appdata` only. Use Testing status (with test users) while building; a test user's grant expires after 7 days. Set it to **In production** before the first release that ships the feature.
- Homepage `https://ledgerlylab.com` and the privacy page from P2.
- OAuth clients, each registered once:
  - Android release: `com.example.ledgerly` plus the SHA-1 of the release keystore that `android-release.yml` signs with. Register the exact SHA-1 of the keystore that signs the APK under test: a mismatch surfaces as `canceled` right after the account is picked, which looks like a user cancel (see [Risks](#risks--known-limitations)).
  - Web: its client ID becomes `GoogleAuthService._webClientId` (commit 6).
  - iOS: bundle id `com.example.ledgerly`. Its client ID becomes `GIDClientID` and its reversed ID the URL scheme in `ios/Runner/Info.plist` (commit 5).
  - Android debug (optional): a developer's `~/.android/debug.keystore` SHA-1. CI debug APKs get a new keystore on every run, so sign-in never works in them.

### P2 — Privacy page on ledgerlylab.com

The consent screen cannot be set to In production without a privacy-policy URL, and `site/src/` has none. Add `site/src/content/docs/privacy.md` (served at `https://ledgerlylab.com/privacy/`) and a sidebar entry in `site/astro.config.mjs`. It must say:

- backup is opt-in and goes to the user's own Drive `appDataFolder`;
- the developer runs no server and cannot read the backup;
- the backup is not encrypted, and anyone who can sign in to that Google account can restore it;
- connecting gives Ledgerly the Google account's email address (and the basic profile Google Sign-In returns); the app stores the email in its database on the device, to remember which account this device backs up to, and shows it on the Backup screen. The email is therefore also in the Drive backups and in Android Auto Backup and iOS device backups. Disconnect clears it on the device; earlier backups still hold it;
- Disconnect stops backups on that device only. To remove Ledgerly's access to the Google account on every device, remove Ledgerly under the Google Account's third-party connections;
- removing Ledgerly's access, or uninstalling it, does not delete the backups. Delete them on the Backup screen, or in Google Drive on the web under Settings → Manage apps → Ledgerly → Delete hidden app data;
- the consent screen's App Domain may also require a terms-of-service page for an external production app; add one if the console asks for it before publication;
- exchange-rate requests carry only currency pairs, and the update check carries no user data (PRD § Security & Privacy).

It ships in commit 12 and must be live before the consent screen is set to In production. See [Copy that goes stale](#copy-that-goes-stale).

### S1 — Do Android and iOS clients in one project share one `appDataFolder`? (PRD open check 1)

Google does not document it. The indirect evidence (the Picker `appId` is the project number, consent is per project, third-party Drive recovery docs require one project) points to one folder per project. One uncited GitHub issue claims one folder per client.

- **How:** with the P1 clients and the commit-6 services on a throwaway branch with a debug-only button, upload from Android and list from iOS under the same account, then the reverse. Restore each on the other platform.
- **Pass:** each platform lists the other's file with the right `platform` and restores it.
- **If it fails:** change no code. Each platform then lists only its own platform's backups, because the list shows whatever Drive returns. Update `PRD.md` (Decisions → Provider, Known trade-offs) and the privacy page to say restore works only between devices of the same platform. Ask the user before trying a shared-client workaround.

### S2 — Can `AppDatabase` be closed and bootstrap re-run in-process cleanly? (PRD open check 2)

Run it after commit 4, before commit 5 starts.

- **Automated:** `test/unit/app/bootstrap_restart_test.dart` passes (cases under [Testing](#testing)).
- **On a device** (Android and iOS, profile build, with a debug-only button on a throwaway branch that stages a copy of the current database plus one extra transaction and calls the restart):
  - Home shows the staged data in the same session; Home, Analysis and Settings work afterwards;
  - a second restart in the same session works;
  - with no FX request in flight at each restart (wait a few seconds after launch or after the previous restart), `flutter logs` shows no exception. An FX upsert that lands after the close throws drift's `StateError` (see [Risks](#risks--known-limitations)); that one line is expected, not a failure;
  - after three restarts, DevTools memory shows one live `AppDatabase` and one live `ProviderContainer`. Old `GoRouter` objects are allowed: `routerProvider` never disposes its router, and each leaked one stops listening once its `Router` widget unmounts.
- **If it fails:** drop `appRestartProvider` and the `start()` split in `bootstrapFor`. After staging, the screen shows a new string, "Close and reopen Ledgerly to finish restoring.", and disables every action. The next cold start applies the staged file (commit 3 already does this). Change the last sentence of `backupRestoreConfirmBody` and `backupRestoreOfferBody` (en, zh_TW, zh_CN) and `PRD.md` § Restore to match. iOS apps may not quit themselves, so do not call `SystemNavigator.pop()`. After staging, the controller stays in `working(restore)` for the rest of the process: `_run` does not reset it, so `PopScope` keeps blocking back and the working guard refuses every command, including `backUpIfDue`. The restoring body shows the new string in place of `backupRestoring`. No route away from the Backup screen is allowed, because any write would go to a database the next cold start discards. Add a controller test (after `restore` succeeds the state is still `working(restore)` and `backUpIfDue` does nothing) and a widget test (pop is blocked after staging). Do this in a new commit, `refactor(app): finish a restore on the next cold start`, not by rewriting commit 4.

### S3 — `google_sign_in` and Drive behaviour on devices

Run with the P1 clients on Android and iOS, after commit 6, on a throwaway branch like S1's: debug-only buttons that call the commit-6 services directly (`GoogleAuthService.connect`, `accessToken` and `signOut`; `GoogleDriveService.accountEmail`, `list` and `upload`). The Backup screen and `BackupRepository` do not exist yet, so in the rows below Connect, Disconnect, a backup and a silent token request mean those buttons.

| # | Check                                                                                                                                                                                                                                                                                                                                 | Pass                                                                                                                                                                                                                                                                                                                                                          | If it fails                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|---|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| a | On an Android device signed in to two Google accounts, A and B: Connect A, Disconnect, then Connect B, so both accounts have granted Ledgerly. Force-stop and relaunch, call `GoogleSignIn.instance.authorizationClient.authorizationForScopes([drive.appdata])`, and send its token to `about.get`; record the email. Repeat on iOS. | It returns a token for B and shows no UI. The account check (D-19) stays, as cheap protection for cases nobody documents: an account removed from the device, an email change, a database copied from another phone.                                                                                                                                          | A token for A: the account check shows the reconnect body, so nothing is written to A. Reconnect B and repeat. If the token still belongs to A, the public API cannot bind a silent token to an account on Android: stop and bring it to the user. The only fix is an Android-only call to `GoogleSignInPlatform.instance.clientAuthorizationTokensForScopes(ClientAuthorizationTokensForScopesParameters(request: AuthorizationRequestDetails(scopes: _scopes, userId: null, email: <stored email>, promptIfUnauthorized: false)))`. It needs a direct `google_sign_in_platform_interface: ^3.1.0` dependency, new import bans and layer-test entries; iOS ignores the email and keeps the instance path. No token: run the same Android-only email-bound call from the debug branch; it names the stored account, so an account that granted Ledgerly gets a token with no UI. If it does, bring the result to the user with that call as the proposed fix (it needs the dependency above). If it also returns no token, stop and bring the result to the user: automatic backups would then need UI, which the PRD rules out. |
| b | `GET https://www.googleapis.com/drive/v3/about?fields=user(emailAddress)` with only `drive.appdata`. The account check (D-19) depends on it.                                                                                                                                                                                          | `user.emailAddress` is present.                                                                                                                                                                                                                                                                                                                               | If S3-a gave B: drop the account check. The stored email from `authenticate()` stays the only record of the account, and Risks gains the residual risk (a silent token for another account goes unnoticed). If S3-a gave A: the simplest fallback is to add `https://www.googleapis.com/auth/userinfo.email` to `_scopes` (non-sensitive; it needs no verification and adds no consent entry beyond the scope line) and read the account from `GET https://www.googleapis.com/oauth2/v3/userinfo`. Ask the user first because it changes D-9. Either way record what `about.get` returns when `user` exists but `emailAddress` is absent: `BackupRepository` must map that to `failed(unknown)` with `errorSnackbarGeneric`, not to Reconnect (D-19 fires only on a different or missing token).                                                                                                                                                                                                                                                            |
| c | Local Disconnect, with two devices on one account: (i) Disconnect on device 1; (ii) on device 1, a debug-only silent token call; (iii) Connect again on device 1; (iv) in that Connect, pick another account that has a backup.                                                                                                       | (i) Device 2 still gets a silent token and uploads through `GoogleDriveService.upload`, and Ledgerly is still listed under the account's third-party connections. (ii) Record the result; a token here changes nothing, because the null stored email stops every silent call. (iii) The account picker appears, and an account that already granted gets no consent screen. (iv) The list shows that account's backups. | (i) Device 2 stops: stop and investigate before shipping Disconnect. (iii) iOS skips the account chooser (the plugin sends no `prompt=select_account` and has no option to force it): record it under Risks.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| d | The final upload `PUT`, after the initiating `POST` asked for `fields=id,size`.                                                                                                                                                                                                                                                                                   | The PUT response is the files resource and carries `size`.                                                                                                                                                                                                                                                                                                                                  | After the upload, read the size with `GET files/{id}?fields=size`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| e | Optional simplification: `GoogleSignIn.instance.authorizationClient.authorizeScopes([...])` with no prior `authenticate()`.                                                                                                                                                                                                           | It shows the account chooser and consent in one flow on both platforms.                                                                                                                                                                                                                                                                                       | Keep the PRD's `authenticate` + `authorizeScopes`. A pass would let us drop `authenticate` and read the email from `about.get` instead, but that changes the PRD design, is only safe if S3-b passes, and the Web client must still exist for Android whenever `authenticate` runs (`initialize(serverClientId:)`). Ask the user first.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| f | Turn on airplane mode more than 1 h after the last token request, then request a silent token (`accessToken()`) and call `about.get` from the debug buttons, on each platform.                                                                                                                                                                                                  | Record the exception type and code that the silent token request throws.                                                                                                                                                                                                                                                                                      | Expected today: Android `GoogleSignInException(unknownError)` ("Authorization failed: …"), iOS `PlatformException`, both `unknown`. If the type and code are stable, map them to `noNetwork` in `BackupRepository` and restore AC8's original wording. If Android instead returns a null token, record that the screen wrongly offers Reconnect (D-19) and bring it to the user.                                                                                                                                                                                                                                                                                                                                       |
| g | Android: pick an account in Connect, then press Back on the Drive consent screen.                                                                                                                                                                                                                                                     | A generic error; nothing connected.                                                                                                                                                                                                                                                                                                                           | If the user should see no message here, ask before matching on the exception description.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |

---

## Decisions

### User decisions (2026-11-19)

| #    | Topic                | Decision                                                                                          |
|------|----------------------|---------------------------------------------------------------------------------------------------|
| D-1  | App id               | Keep `com.example.ledgerly` on Android and iOS.                                                   |
| D-2  | Encryption           | None. The screen says the backup is unencrypted.                                                  |
| D-3  | Provider on iOS      | Google Drive, not iCloud.                                                                         |
| D-4  | "No cloud" copy      | OK to change it in the README and on the site.                                                    |
| D-5  | Where restore runs   | Only from Settings → Backup.                                                                      |
| D-6  | Automatic backups    | Only while the app is open. No `workmanager`.                                                     |
| D-7  | OS backups           | Android Auto Backup and iOS device backup stay on as a free fallback.                             |
| D-8  | Homepage and privacy | `https://ledgerlylab.com/`, with a privacy page on that site.                                     |
| D-9  | Account              | The user's own Google account via `google_sign_in`, `drive.appdata` scope only. Not an app login. |
| D-10 | Backups kept         | Exactly one, the latest, per device.                                                              |
| D-11 | OAuth clients        | Registered once, not per release.                                                                 |

### Defaults chosen without asking (2026-11-19, revisitable)

| #    | Default                                                                                  | Status in this spec                                                                    |
|------|------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| D-12 | `backup_frequency` defaults to `off`.                                                    | Kept.                                                                                  |
| D-13 | After a restore, write a new `device_id` and clear `last_backup_at`.                     | **Replaced by D-15.** It breaks D-10; see [Deviations from PRD](#deviations-from-prd). |
| D-14 | Restore brings back theme, locale, splash settings and default currency from the backup. | Kept: every `user_preferences` row except those D-15 sets comes from the backup.       |

### Decisions made in this spec (2026-11-23)

The user approved these on 2026-11-23, except the first D-16: an account-wide Disconnect through Google's revoke endpoint, which the user rejected. The D-16 below replaces it, D-19 changes with it, and D-25 is the use case the user added the same day.

| #    | Topic                       | Decision                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
|------|-----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| D-15 | Device identity on restore  | The staged file keeps this device's `device_id` only when the backup was made by this device (the file's `appProperties['device_id']` equals this device's id); a backup from another device gives this device a new UUID instead, written to the staged file and to this device's `device_id` preference, so the next backup can never prune that device's file. It gets this device's `backup_account_email` row, and its `backup_frequency` row if this device has ever set one (otherwise the backup's stays). Its `last_backup_at` is set to the restore time, so for one period after a restore no automatic backup runs and this device's pre-restore backup is not pruned. A device that has no `device_id` gets a new UUID first. A same-device restore therefore keeps one backup for the device; restoring another device's backup takes a new id, and two devices never share an id through a restore. A cross-device restore leaves this device's pre-restore file as another device's backup (it is the rollback path); the user can delete it.                                                                                                                                                                                                                                                                                                                                                                |
| D-16 | Disconnect                  | This device only. It clears `backup_account_email`, sets `backup_frequency` to `off`, and calls `GoogleSignIn.signOut()`. No revoke and no `GoogleSignIn.disconnect()`, so it needs no network. The Google grant stays on the account, so other devices keep backing up, and the backups stay in Drive. Connecting again shows the account picker on Android (on iOS Google's sign-in page decides whether to show its chooser; S3-c), so the user may pick another account, and the frequency reads Off until the user picks one. Removing Ledgerly's access on every device is done on the Google Account's third-party connections page; the app has no full revoke. Replaces an account-wide Disconnect (Google's revoke applies to the whole Cloud project), which the user rejected on 2026-11-23.                                                                                                                                                                          |
| D-17 | Automatic trigger           | After the first frame, and on `AppLifecycleListener.onShow` (the app comes back from the background). Not on every `onResume`, which also fires for the notification shade, Control Center and the Connect account picker.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| D-18 | Controller states           | `idle`, `working(BackupJob)` and `failed(BackupFailure)`. No `done`: the refreshed "Last backup" line confirms success, and a `keepAlive` controller would show `done` on every later visit.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| D-19 | Connected / reconnect       | Stored per device in `backup_account_email`: the email of the account picked in the last Connect; null means not connected, and nothing calls `google_sign_in` then. The silent token request names no account (on Android, `GoogleSignIn.instance.authorizationClient` sends none, so the native client uses the app's default account; on iOS it restores the one keychain user). So every command that uses a silent token first checks Drive `about.get`'s `user.emailAddress` against the stored email, ignoring case (S3-a, S3-b). A null token or another account's token is `notAuthorized`, and the screen offers Reconnect. Changed 2026-11-23 with D-16: it was inferred from a silent token and `backup_frequency`, which stops working once a grant outlives Disconnect.                                                                                                       |
| D-20 | Older backups               | Migrated forward on the staged copy before it is staged, so the only work left after the old database closes is a rename and an open at the current schema.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| D-21 | Upload check                | Compare the uploaded `size` with the snapshot's length. No `md5Checksum` compare: TLS covers transit, and the restore runs `quick_check` anyway.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| D-22 | Retries                     | None, and no backoff. The next due check or a tap retries.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| D-23 | Client IDs                  | Committed as constants: the Web client ID in `google_auth_service.dart`, the iOS client ID in `Info.plist` (it must be a literal there anyway). The Web client ID is Android-only, where Credential Manager needs it as `serverClientId`; iOS identifies the app with `Info.plist`'s `GIDClientID` and needs no server client ID because no server auth code is requested. OAuth client IDs for installed apps are not secrets.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| D-24 | Frequency control           | `RadioGroup` (as `account_filter_sheet.dart` uses `RadioGroup<int>`) around three `RadioListTile` rows (new to `lib/`; that sheet puts a bare `Radio<int>` in its own row widget), not a three-segment `SegmentedButton`, which is likely to overflow at 2× in a 390dp width.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| D-25 | Restore offer after Connect | After every successful Connect or Reconnect tap, the screen asks whether to restore the account's newest backup, if that backup was created after this device's `last_backup_at` and is restorable. A device with no `last_backup_at` (it has never backed up or restored) is offered the newest restorable backup only while its `transactions` table is empty: a Restore there could not be undone from Drive, because the device has no backup of its own yet, and the list's Restore stays available (user decision, 2026-11-23). Restore takes the same path as the list's Restore; Cancel does nothing, and the backup stays in the list. Never at launch, on screen open or automatically (D-5), and no "dismissed" flag is stored. The time rule leaves out this device's own backups (their `created_at` is at or before `last_backup_at`). It can offer a false clone ([Risks](#risks--known-limitations)), this device's own upload whose response was lost; restoring it rolls back what was entered after it, as restoring this device's own backup from the list would. A newest backup that is not restorable gives no offer; the list already says "Update Ledgerly". An existing device that reconnects while another device has a newer backup is offered it too, and can Cancel (user decision, 2026-11-23). |
| D-26 | Overdue backup on the Settings tile | When automatic backup is on and this device's last backup is at least twice the period old (48 hours for Daily, 14 days for Weekly), or it has none, the Settings → Data Management tile shows a subtitle ("Last backup N days ago", or "This device has no backup yet."). An automatic backup that keeps failing is otherwise visible only on the Backup screen (user decision, 2026-11-23). |

### Deviations from PRD

Each one changes `PRD.md` in the same change as this spec (commit 1).

1. **Device identity after a restore** (PRD.md:720 "this device's last successful backup", PRD.md:721 "a new one is written after every restore", PRD.md:1000 "write a new device_id and clear last_backup_at", PRD.md:1068 "every table matches the backup"). Replaced by D-15. *Reason:* the most common restore is a device restoring its own backup. With a new id, the device's own backup becomes "another device's" backup that the app never deletes, and the next backup adds a second file, which breaks D-10. Clearing `last_backup_at` would make the restored data back up at once on the first frame after the restart, and that backup would prune this device's pre-restore backup, the only way back from a wrong restore; setting it to the restore time keeps that backup for one period. Writing the identity rows into the staged file also means a cold start that finishes a restore needs no further preference writes; only a cross-device restore's new `device_id` is written to the preferences before staging. *PRD change:* line 720 becomes "ISO 8601 UTC time of this device's last successful backup or restore, nullable"; line 721 becomes "random id that tags this device's backup in Drive; kept through a restore of this device's own backup (a restore of another device's backup, and a device without one, gets a new one), and replaced before a backup that finds a newer Drive file with the same id"; line 1000 goes, replaced by the diagram in item 4; line 1068 becomes "Repository round trip: back up, change data, restore; every table matches the backup, except that `backup_account_email` keeps this device's value, `device_id` keeps it when the backup came from this device and is a new one otherwise, `backup_frequency` keeps this device's value when it has one, and `last_backup_at` is the restore time."
2. **No `done` state** (PRD.md:1034 `idle | working | done | failed(BackupFailure)`). Replaced by D-18. *PRD change:* `idle | working(job) | failed(BackupFailure)`.
3. **Where `BackupFailure` lives** (PRD.md:1034 places it in `backup_state.dart`). It moves to `lib/domain/models/drive_backup.dart`, and `BackupException` sits beside it. *Reason:* `BackupRepository` throws it inside `BackupException`, and repositories may not import `ui/`. The screen must also tell a `notAuthorized` load error of `backupAccountProvider` from other errors (D-19), and widgets may not import `data/` (`widgets_forbid_data_internals`), so the exception cannot live in `backup_repository.dart`. The nearest precedent is `CsvFileErrorKind` and `CsvFileException` (`lib/domain/models/csv_import.dart`): a domain enum carried by a domain exception from below the UI and switched on by the screen. The app-update slice instead keeps `UpdateFailure` in `app_update_state.dart` and throws one exception class per failure; here one `BackupException(failure)` is shorter than five classes. *PRD change:* that bullet names the domain model file.
4. **Where the restore download lands** (PRD.md:994-996 "download to a temp file … move it next to the database"). It downloads straight to `<documents>/ledgerly.sqlite.restore.part`, is checked there, and is renamed to `ledgerly.sqlite.restore`. *Reason:* Dart's `File.rename` does not copy across filesystems, so a same-directory rename is the only atomic step that needs no assumption about the cache and documents directories. *PRD change:* lines 994-1000 become:

   ```text
     → download to <documents>/ledgerly.sqlite.restore.part
     → check it: PRAGMA quick_check; reject user_version above schemaVersion
     → keep this device's device_id when the backup came from this device;
       otherwise write a new one. Give it this device's backup_account_email, this
       device's backup_frequency if it has one, and last_backup_at = the restore time
     → if user_version is below schemaVersion, open it once with AppDatabase to migrate it
     → rename it to ledgerly.sqlite.restore
     → close AppDatabase → run bootstrap() again with a new ProviderScope
     → bootstrap, before opening the database: delete any leftover ledgerly.sqlite-journal,
       rename ledgerly.sqlite.restore over ledgerly.sqlite, then open
   ```
5. **"When the app resumes"** (PRD.md:1011). Replaced by `onShow` (D-17). *PRD change:* "when the app comes back from the background".
6. **When the open checks run** (PRD.md:949 "before building it", PRD.md:1061 "before writing the feature"). S2 needs the commit 3–4 restart code and S1 needs the commit 6 services, so each check runs right after the commit that provides its code and before the next commit starts. *PRD change:* line 949 ends "Run the two checks under [Open checks](#open-checks) at the points the design spec's commit plan names.", and line 1061 becomes "Run each check before the code that depends on it:".
7. **The connection is stored on the device** (PRD.md:718-721 Cloud backup keys, PRD.md:964 Token storage, PRD.md:1435 Security & Privacy). D-19. *Reason:* with a local Disconnect (item 8) the grant outlives Disconnect, so a silent token no longer means "connected", and one device can hold grants for several accounts. *PRD change:* the keys list gains "`backup_account_email` — email of the Google account connected on this device, nullable; null means not connected"; line 964 gains "It stores only the connected account's email, in `user_preferences`."; in line 1435, "The app stores no OAuth token," becomes "The app stores no OAuth token (only the connected account's email, which is therefore also in the Drive backups and in OS backups),".
8. **Disconnect affects only this device** (PRD.md:962 Authentication, PRD.md:1020 Settings > Backup). D-16. *Reason:* the user rejected an account-wide Disconnect on 2026-11-23. Google's revoke removes the grant for the whole Cloud project, so it would stop backups on every device using the account. *PRD change:* line 962 gains "Disconnect signs out on this device only: it clears the stored email and sets `backup_frequency` to `off`. The grant stays, so other devices keep backing up. Removing Ledgerly's access everywhere is done on the Google Account's third-party connections page; the app has no full revoke."; line 1020 becomes "Connect Google; once connected, the account's email and Disconnect (also offered when the account needs reconnecting or Drive cannot be reached), whose confirmation says it stops backups on this device only".
9. **Silent tokens are checked against the stored account** (PRD.md:1012 Automatic backup, PRD.md:1031 Architecture, PRD.md:1042 Error Handling). D-19. *Reason:* the silent token request names no account, so on a device where several accounts granted Ledgerly the token could belong to another one. *PRD change:* line 1012 becomes "Runs when this device is connected (`backup_account_email` is set), `backup_frequency` is not `off`, and `last_backup_at` is missing, in the future, or older than the period (20 hours for Daily, 6 days 20 hours for Weekly), and the silent authorization call returns a token for the connected account (checked with Drive `about.get`). On a device that is not connected the check stops at once, without calling Google. With no token, or another account's token, the backup is skipped and the Backup screen offers Reconnect."; line 1031 gains "`about.get` with `fields=user(emailAddress)` for the account check," before "`files.list` with `spaces=appDataFolder`"; line 1042 becomes "Authorization missing or revoked, or a silent token for another Google account than the connected one → `notAuthorized`; automatic backups are skipped and the screen offers Reconnect."
10. **A restore offer after Connect** (PRD.md:1026 Settings > Backup). D-25. *Reason:* the user's new-phone use case (2026-11-23). *PRD change:* after line 1026 add "After a successful Connect or Reconnect, if the account's newest backup is restorable and newer than this device's last backup (on a device that has never backed up, only while it holds no transactions), the screen asks whether to restore it. The offer never appears at launch or on its own; restore still runs only from Settings."
11. **When `last_backup_at` is written** (PRD.md:981-982 Backup diagram). [Backup flow](#backup-flow) step 10 writes it before pruning, and step 12 deletes the snapshot in `finally`. *Reason:* a process killed during the prune then leaves no own file newer than `last_backup_at` for the clone check (step 4) to mistake for a clone. *PRD change:* lines 981-982 become three lines: `→ write last_backup_at`, `→ delete this device's previous backup`, `→ delete the temp file`.
12. **An overdue subtitle on the Settings tile** (PRD.md:1026 Settings > Backup). D-26. *Reason:* the user's decision on 2026-11-23, so that an automatic backup that keeps failing does not go unnoticed. *PRD change:* after the restore-offer paragraph add "When automatic backup is on and this device's last backup is at least twice the period old, the Settings tile shows how long ago the last backup was; when this device has no backup yet, the subtitle reads 'This device has no backup yet.'"
13. **The automatic trigger is imperative** (PRD.md:1013 "The trigger tracks what it has already requested: writing `last_backup_at` makes the preference stream emit again"). D-17. *Reason:* nothing watches `last_backup_at` for a trigger; the first-frame hook and `onShow` call the controller directly, and its `working` guard is the single owner of "already requested". The Settings tile's `watchLastBackupAt` is a display-only watcher and starts no backup. *PRD change:* line 1013 becomes "The triggers are imperative calls from the first-frame hook and `AppLifecycleListener.onShow`; the controller's working guard is the single owner of what has already been requested, so writing `last_backup_at` starts no backup. The Settings tile watches it only for its subtitle."
14. **The privacy page also says what deleting data takes** (PRD.md:1051 Google Cloud Setup, privacy-policy bullet). P2. *Reason:* the consent screen requires the page before In production, and users must know that uninstalling or removing access does not delete the backups and where to delete them. *PRD change:* line 1051 gains ", and removing Ledgerly's access or uninstalling it does not delete the backups (with how to delete them)."

`PRD.md`'s routing table (lines 1083-1106) also lacks `/settings/export`, and `README.md:251` ("CSV export") and `site/src/content/docs/ledgerly-guide/mvp-limitations.md:17` ("CSV import/export") are already stale. Those are out of scope here (AGENTS.md § 3), so mention them in the PR description.

---

## User Flow

```
Settings ─▶ "Google Drive backup" tile ─▶ /settings/backup  (BackupScreen, modal route)
  stored email? ── no ──▶ [Not connected]  (no google_sign_in call)
     │ yes
  [Loading]        spinner: silent token → Drive about.get (account check) + files.list
     │                    ├── no token, or another account's token ──▶ [Reconnect]
     │                    └── other error ──▶ [Load failed] "Couldn't reach Google Drive." · [Retry] · [Disconnect]
     ▼
  [Not connected]  intro · scope note · privacy note · [Connect Google account]
  [Reconnect]      the same, plus "Ledgerly can no longer reach your Google Drive…" · [Reconnect] · [Disconnect]
     │ tap
     ▼
  account picker + consent (google_sign_in) ── picker cancelled ──▶ back, no message
     │                                       └─ consent cancelled (Android) ──▶ generic error
     │ granted: store the email, list the account
     ├── newest backup restorable, and created after last_backup_at
     │   (never backed up: only while no transactions)  (D-25)
     │      ──▶ "Restore from Google Drive?" ── Restore ──▶ [Restoring…] (as below)
     │                                       └─ Cancel ──▶ [Connected]
     ▼
  [Connected]
     • Google account   email · [Disconnect] ─▶ confirm ─▶ this device only: email cleared,
                                                  frequency = off, sign out ─▶ [Not connected]
     • Automatic backup (•) Off  ( ) Daily  ( ) Weekly   "Automatic backups run while Ledgerly is open."
     • [Back up now] ─▶ "Backing up…" ─▶ list refreshes, "Last backup: …"  │ failure ─▶ message
                                                                            (notAuthorized: message + [Reconnect])
     • Backups in Google Drive   newest first; each row: date and time,
                                 "This device · " + platform · Ledgerly version · size
         ⋮ Restore ─▶ confirm ─▶ [Restoring…]  (back blocked)
                                   ├── failure ─▶ [Connected] + message; local data unchanged
                                   └── staged  ─▶ in-process restart ─▶ Home on the restored data
         ⋮ Delete  ─▶ confirm ─▶ deleted from Drive ─▶ list refreshes

App first frame, or back from background ─▶ due? ─▶ same path as "Back up now", no UI change
                                             (not connected, off, not due, or already working ─▶ nothing)
```

**A new phone (D-25).** A fresh install has no `device_id`, no `last_backup_at` and no stored email, and the first-run seed adds no transactions, so it shows Connect, and Connect offers the account's newest backup if it is restorable. If the user already entered transactions before connecting, there is no offer, and the list's Restore still works. A phone the OS migrated (Android Auto Backup, iOS device transfer) starts with a copy of the old phone's database, including its `backup_account_email`, but not with the old phone's Google session. On iOS the keychain session is saved as `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` and does not move to a new device. On Android the app's default account is set by a Connect on that phone, and an authorization request with no saved account returns a `PendingIntent`, which the plugin turns into a null token. So the screen shows the reconnect body, and Reconnect offers the old phone's backup if it is newer than the copy's `last_backup_at`. If Android does return a token for the stored account, the screen shows the connected body, and the old phone's backup is in the list.

The controller drives every state change. The screen renders state and forwards taps, following the "no try/catch in widgets" rule in `layers.md`.

---

## Drive file format

- **Space:** `appDataFolder`. Only this Cloud project's clients can read it, and the Drive UI cannot show it. Its files cannot be trashed, so `files.delete` is permanent.
- **Name:** `ledgerly.sqlite`. Drive names are not unique; the code identifies files by `id` only.
- **MIME type:** `application/vnd.sqlite3` (IANA-registered).
- **Content:** a `VACUUM INTO` snapshot of the live database. `VACUUM INTO` copies `user_version`, so the file's own `user_version` equals the `schemaVersion` of the app that made it.
- **`appProperties`** (private to this app):

| Key              | Value                                                        | Example                                | Key + value bytes |
|------------------|--------------------------------------------------------------|----------------------------------------|-------------------|
| `schema_version` | the app's `schemaVersion`, read as `_db.schemaVersion`, as a decimal string | `8`                                    | 15                |
| `app_version`    | `PackageInfoService.read()` → `.version`                     | `0.10.4`                               | 17                |
| `created_at`     | The repository clock, `toUtc().toIso8601String()`            | `2026-11-23T14:05:09.123Z`             | 34                |
| `platform`       | `Platform.operatingSystem`                                   | `android` or `ios`                     | 15                |
| `device_id`      | The `device_id` preference, a UUID v4                        | `3f1c…` (36 characters)                | 45                |

- **Never in `appProperties`:** counts, totals, currency lists, account or category names, or anything else from the ledger (PRD.md:986).
- **Limits:** Drive allows 30 private properties per file per app and 124 bytes per property (key plus value, UTF-8). Five keys of at most 45 bytes fit. A file can be up to 5,120 GB. The upload sends the whole file in one `PUT`, so the 256 KB chunk rule does not apply.
- **Storage:** hidden app data counts toward the user's Google storage. During a backup the new file is uploaded before the old one is deleted, so the account briefly holds two copies of this device's backup.
- **Parsing a listed file:** a file with a missing key, or whose `schema_version` or `created_at` does not parse, is left out of the list and out of the clone check. Pruning matches on `device_id` alone, so a file without one is never deleted.

---

## Backup flow

`BackupRepository.backUp()`, called by `BackupController` for "Back up now" and for an automatic backup:

1. `token = await _token()`, the account check (D-19, see [Repository](#repository)): a null stored email, a null silent token, or a token whose Drive `about.get` email is not the stored one → `BackupException(notAuthorized)`.
2. `deviceId = await _deviceId()`: the stored id, or a new `const Uuid().v4()` written with `setDeviceId`.
3. `previous = await _drive.list(token)`. This runs before the snapshot, so an offline attempt fails fast without writing one.
4. **Clone check.** `last = await _prefs.getLastBackupAt()`. If some file in `previous` has `appProperties['device_id'] == deviceId` and either `last` is null or the file's parsed `created_at` is after `last` (`isAfter`), another install shares this id (an OS backup, a device migration or a reinstall copied `ledgerly.sqlite`). Set `deviceId = const Uuid().v4()` and `await _prefs.setDeviceId(deviceId)` before the upload, so step 11 deletes nothing. This device's own files have `created_at` equal to `last_backup_at` (both come from the single `now` in step 8) or, after a restore, before it. A null `last` means this install has never finished a backup or a restore, yet it can already hold an id: step 2 stores one before an offline first attempt fails at step 3, and `stageRestore` stores one before its download. A same-id file then came from another install that copied this database, or is this device's own upload whose response was lost (a false clone, see [Risks](#risks--known-limitations)), so taking a new id is always safe.
5. `snapshot = await _files.snapshotFile()`: `<cache>/ledgerly-backup.sqlite`, deleted first if a killed process left it there, because `VACUUM INTO` refuses an existing file.
6. `await _db.exclusively(() => _db.customStatement('VACUUM INTO ?', [snapshot.path]))`, as Drift's own devtools export does. `exclusively` takes sole use of the connection without a transaction, which `VACUUM INTO` needs.
7. Check the snapshot with `_attached(snapshot.path, _check)` (see [Restore flow](#restore-flow)). Its `user_version` must equal `_db.schemaVersion`; otherwise throw `BackupException(corrupt)`.
8. `now = _clock()`, read once and used for `created_at` and step 10. `uploaded = await _drive.upload(token, snapshot, appProperties)` with the keys above.
9. If `uploaded.size != await snapshot.length()`, `await _drive.delete(token, uploaded.id)` (by id, so only the file just created), then throw `BackupException(corrupt)`.
10. `setLastBackupAt(now)`. It comes before pruning, so a process killed during the prune leaves no own file newer than `last_backup_at` for step 4 to mistake for a clone.
11. Delete every file in `previous` whose `appProperties['device_id'] == deviceId`. Files of other devices, and files without a `device_id`, are never touched. A failed delete here is reported like any other failure; the new backup and `last_backup_at` stay, and the next backup prunes the leftover file.
12. In `finally`, delete the snapshot.

If any step fails, the device's previous backup stays in Drive (PRD.md:987). `DioException`s map to `BackupFailure` as in [Error Handling](#error-handling).

---

## Restore flow

`BackupController.restore(DriveBackup b)` reads `appRestartProvider` before its first `await`, then calls `BackupRepository.stageRestore(b)` and the restart:

```text
Restore ─▶ confirm (date and time; "replaces all data on this device")
  ▶ BackupRepository.stageRestore(b)
      _token(), or notAuthorized                   (the account check, D-19)
      _deviceId()                                  (a device without one gets a new UUID now)
      b.deviceId == this id? keep it : new UUID + setDeviceId(...)  (D-15: a backup from another
                                                    device must not prune that device's file)
      download → <documents>/ledgerly.sqlite.restore.part  (any leftover .part and .part-journal
                                                            deleted first)
      _attached(part):  quick_check + user_version  (any error, not 'ok', or < 1 → corrupt)
                        user_version > schemaVersion → newerSchema
                        staged.user_preferences: the resolved device_id, this device's
                        backup_account_email, its backup_frequency if it has one, and
                        last_backup_at = the restore time (D-15)
      user_version < schemaVersion → open the .part once with AppDatabase to migrate it, quick_check
      DatabaseFileService.stageRestore()            (rename .part → ledgerly.sqlite.restore)
      finally: delete the .part and its -journal if still there (the .part is not, once staged)
  ▶ appRestart()                                    (the closure bootstrapFor installed)
      runApp(SizedBox.shrink())  → await endOfFrame   (the old ProviderScope unmounts and
                                                       disposes its container)
      await db.close()
      start(): applyStagedRestore → open AppDatabase → date data → read prefs → seed (skipped)
               → runApp(new ProviderScope with fresh one-shot overrides)
```

### Checking a file: `_attached`

Both flows check a file from the open connection with `ATTACH`, so no second Drift instance runs migrations on a file that might be newer, and `sqlite3` does not become a direct dependency:

```dart
Future<T> _attached<T>(String path, Future<T> Function() body) =>
    _db.exclusively(() async {
      await _db.customStatement('ATTACH DATABASE ? AS staged', [path]);
      try {
        return await body();
      } finally {
        await _db.customStatement('DETACH DATABASE staged');
      }
    });
```

`_check()` reads `PRAGMA staged.quick_check` (every row must be `ok`) and `PRAGMA staged.user_version` with `customSelect`, and returns the version. A row other than `ok`, or a version below 1, throws `BackupException(corrupt)`. The catch wraps the whole `_attached(path, _check)` call, not just `_check()`. SQLite reads the schema during `ATTACH`, so a non-database or truncated file already fails there (`SQLITE_NOTADB` 26 or `SQLITE_CORRUPT` 11); only an empty file attaches, with `user_version` 0. The catch rethrows `BackupException`, so `newerSchema` survives, and maps every other exception to `corrupt`. The broad type matters because the error arrives as `DriftRemoteException` on a device and as `SqliteException` in in-memory tests.

A version below 1 must be rejected: Drift would treat the file as new and run `onCreate` over its tables. A version above `schemaVersion` must be rejected before Drift ever opens the file, because Drift's `onUpgrade` also runs on a downgrade: none of Ledgerly's `if (from < N)` steps would fire, and the file would be stamped with the older version (PRD.md:1005).

### Carrying the device identity (D-15)

Inside the same `_attached` block, after the version checks:

```sql
DELETE FROM staged.user_preferences
  WHERE key IN ('device_id', 'backup_account_email', 'last_backup_at')
     OR (key = 'backup_frequency'
         AND EXISTS (SELECT 1 FROM main.user_preferences WHERE key = 'backup_frequency'));
INSERT INTO staged.user_preferences
  SELECT key, value FROM main.user_preferences
  WHERE key IN ('device_id', 'backup_account_email', 'backup_frequency');
INSERT INTO staged.user_preferences (key, value) VALUES ('last_backup_at', ?);
```

The `?` is bound to `jsonEncode(_clock().toUtc().toIso8601String())`, the encoding `setLastBackupAt` writes. The `INSERT … SELECT` copies the raw JSON rows, so their encoding is not repeated. `main` always has a `device_id` here, because `_deviceId()` ran first; `stageRestore()` has already rewritten it when the backup came from another device, and `_token()` guarantees a non-null `backup_account_email`. The connection belongs to the device (D-19), like its `device_id`, so a restore never changes which account this device is connected to. A device that has never written `backup_frequency` keeps the backup's row, so a new phone that restores the old phone's Daily backup stays on Daily (D-14); a device that has set one, including `off` after a Disconnect, keeps its own. `user_preferences` (`key`, `value`) has been in the schema since v1, so this works on every older backup. The key strings repeat the private `_k…` constants of `DriftUserPreferencesRepository`; the round-trip test reads them back through the preferences API, so a renamed key fails it.

### Migrating an older backup before staging (D-20)

When the staged copy's `user_version` is below `schemaVersion`:

```dart
final staged = AppDatabase(NativeDatabase.createInBackground(part));
try {
  final rows = await staged.customSelect('PRAGMA quick_check').get(); // opens + migrates
  if (rows.any((r) => r.read<String>('quick_check') != 'ok')) throw const BackupException(BackupFailure.corrupt);
} finally {
  await staged.close();
}
```

A migration failure then surfaces on the Backup screen while the old database is still open, not as a blank screen after it is gone. Drift prints a debug-only "created the database class multiple times" warning while this second instance is open.

### The file swap: `DatabaseFileService.applyStagedRestore()`

Called by `bootstrap()`'s `openDatabase` closure on the line before the `AppDatabase` constructor. `driftDatabase` wraps its connection in `DatabaseConnection.delayed`, which starts resolving the path and spawning the worker isolate as soon as `AppDatabase` is constructed, so the swap must finish before the constructor runs.

1. If `<documents>/ledgerly.sqlite.restore` does not exist, return. That is one `exists` call on a normal cold start.
2. Delete `<documents>/ledgerly.sqlite-journal` if present. This is load-bearing: a hot journal left by the old file would be rolled back into the restored file on its first open and corrupt it. The database uses the default rollback journal (`beforeOpen` only sets `foreign_keys`), so there are no `-wal` or `-shm` files.
3. Rename `.restore` over `ledgerly.sqlite`. A rename within one directory is atomic. If the process dies before it, the staged file is still there and the next start repeats both steps (the delete is idempotent). After it, the restore is done.

No try/catch: the swap guards nothing that can happen in a sandbox the app owns.

### The in-process restart

`bootstrapFor` wraps steps 2–7 in a local `Future<void> start()` and installs `appRestartProvider.overrideWithValue(restart)` in each `ProviderScope` it launches:

```dart
() async {
  launch(const SizedBox.shrink());
  await WidgetsBinding.instance.endOfFrame;
  await db.close();
  await start();
}
```

- **The interim frame is load-bearing.** A second `runApp(ProviderScope(...))` of the same type and key would reuse the old `ProviderScopeState`, which only calls `container.updateOverrides(...)`. Repositories would rebuild against the new database, but the `splashGateSnapshotProvider` closure would stay bound to the old `preferencesRepo`, and the `keepAlive` controllers would keep their state. If only a new key were used and both trees swapped in one frame, the top-level `_rootNavigatorKey` in `router.dart` would let the new `Navigator` take over the old one's element and route stack. Showing `SizedBox.shrink()` for one frame unmounts the old scope; `ProviderScopeState.dispose` then disposes the container, which cancels the Drift stream subscriptions and the splash-gate subscriptions, closes the shared `Dio`, and disposes the `keepAlive` repositories and controllers. No key is needed.
- **Then `db.close()`.** It closes the stream queries and the executor and shuts down the single-client worker isolate. A closed Drift database cannot be reopened, so `start()` constructs a new `AppDatabase`.
- **Then `start()`.** It runs the swap, re-reads theme, locale, splash and default currency, skips the seed (`first_run_completed` is true in the restored file), and launches a new `ProviderScope` with fresh one-shot overrides. That meets PRD.md:1006 with no extra code.
- **The caller touches nothing afterwards.** The container that owns `BackupController` is disposed partway through `restart()`, so `restore()` returns without writing state or invalidating anything (`ref.mounted` is false).
- **Re-run side effects:** the new `App`'s first frame runs recurring generation (wanted for the restored rules), a second GitHub release check (`AvailableAppUpdate._requested` is per container), an FX refresh and the backup due check (which finds nothing due, because D-15 set `last_backup_at` to the restore time). A query already pending at close fails with `ConnectionClosedException`, which `on Exception` in `ExchangeRateRepository._doRefreshAll`/`fetchRate` swallows; recurring generation's `on Object` in the first-frame closure swallows anything. A query that starts after close (for example an FX upsert after its HTTP response arrives) throws drift's `StateError`, which `on Exception` does not catch, so it surfaces as an uncaught async error from the unawaited `refreshAll(...)` in the repository constructor. It is logged and harmless: the new container refreshes the rates again.

---

## Automatic backup

- **When:** `_AppState._runFirstFrameCallback` (after the update check) and `AppLifecycleListener(onShow:)` both call:

  ```dart
  void _backUpIfDue() => unawaited(
    ref.read(backupControllerProvider.notifier).backUpIfDue(
      after: ref.read(exchangeRateRepositoryProvider).startupRefresh,
    ),
  );
  ```

  Creating the listener in a resumed app fires nothing. If a platform reports its first lifecycle state only after `App.initState`, `onShow` may also fire at launch; the working guard in step 4 below keeps that to one backup. After startup `startupRefresh` has completed, so both call sites pass it and no optional parameter is needed. The listener is created in `initState` and disposed in a new `dispose()` override; after a restart the new `App` creates both again.
- **Why wait for `startupRefresh`:** `VACUUM INTO` runs inside `exclusively` on Drift's single worker. With a rollback journal there is no read pool, so Home's first queries would otherwise queue behind the snapshot. The wait is capped at 30 s, like `AvailableAppUpdate.checkAfter`. Like `checkAfter`, it starts no timer when there is nothing to do: when not connected, `off` or not due it returns before waiting, so app-shell widget and integration tests (`buildTestApp`, `buildBootstrappedTestApp`) never leave a 30 s timer pending (commit 80b1f670).
- **`BackupController.backUpIfDue({required Future<void> after})`:**
  1. Return if the state is `working`.
  2. `due = await repo.isDue()`, inside a catch of `Object` that logs only `${e.runtimeType}` and returns, so the unawaited call cannot throw. Return unless `ref.mounted && due`.
  3. `await after.timeout(const Duration(seconds: 30), onTimeout: () {})`; return unless `ref.mounted`.
  4. Run the "Back up now" path (`_run(BackupJob.backup, …)`), which re-checks `working` synchronously before setting it. That closes the race between the first frame, `onShow` and a tap.
- **`BackupRepository.isDue()`:** reads `backup_account_email` first; null → false (D-19). Then reads `backup_frequency`; `off` → false. Otherwise reads `last_backup_at` and `now = _clock()`: null → true; `now.isBefore(last)` → true (the clock was ahead when it was written, then corrected); else `now.difference(last) >= 20 hours` (Daily) or `6 days 20 hours` (Weekly). The 4-hour slack keeps a user who opens Ledgerly once a day at about the same time on a daily backup: a launch a few minutes short of 24 hours after the last backup would otherwise wait a whole extra day, so Daily would run every other day and Weekly every 8 days (user decision, 2026-11-23). It reads preferences only, so a device that is not connected, or has the default `off`, never touches `google_sign_in`. Every app-shell widget test therefore stays off the plugin channel.
- **No re-trigger:** the triggers are imperative calls. Nothing watches `last_backup_at` for a trigger, so its write starts nothing (Deviation 13 replaces PRD.md:1013, which still described the old reactive design).
- **Silent authorization:** step 1 of [Backup flow](#backup-flow) calls only `authorizationForScopes`, which shows no UI. It never calls `attemptLightweightAuthentication()`, whose second pass on Android opens the Credential Manager account sheet. With no token, or a token for another account (D-19), the run ends in `failed(notAuthorized)`, and the screen offers Reconnect.

---

## Settings > Backup screen

### Entry

In `lib/ui/features/settings/views/settings_screen.dart`, between the export tile and the pending tile in the Data Management `SettingsSection`, so the data-transfer tiles stay together:

```dart
ListTile(
  key: const ValueKey('settingsBackupTile'),
  title: Text(l10n.settingsBackupTile),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push('/settings/backup'),
),
```

No icon, like its neighbours. **Overdue subtitle (D-26).** The tile reads `backupFrequencyProvider` and `backupLastBackupAtProvider` and shows a subtitle only when automatic backup is on and this device's backups have stalled:

- frequency `off`, either stream still loading, or either stream errored → no subtitle (a corrupt preference row must not break the Settings screen);
- `last_backup_at` null → `backupNoBackupYet`;
- `now.difference(last)` at least twice the period (48 hours for Daily, 14 days for Weekly) → `backupTileOverdue(days)` with `days = now.difference(last).inDays`;
- otherwise → no subtitle.

`now` is `DateTime.now()`, read in `build`. This is the only place outside the Backup screen that tells the user automatic backups stopped working: storage full, a lost grant, or a device that has not been opened. `SettingsScreen`'s two `@Dependencies` lists gain `backupFrequency` and `backupLastBackupAt`. Update the file's header comment (lines 8-9), which lists the Data Management tiles.

### Route

In `lib/app/router.dart`, after the `export` route:

```dart
GoRoute(
  path: 'backup',
  parentNavigatorKey: _rootNavigatorKey,
  pageBuilder: (ctx, state) => _modalPage(
    state,
    const _AdaptiveFormRoute(child: BackupScreen()),
  ),
),
```

Below 600dp the screen is edge to edge; from 600dp it sits in the 560-wide dialog. Add `BackupController`, `backupAccount`, `backupFrequency` and `backupLastBackupAt` to `routerProvider`'s `dependencies` next to `CsvExportController` (`backupLastBackupAt` comes in through the Settings tile, like the other `SettingsScreen` dependencies; missing it fails `dart analyze --fatal-infos` with riverpod_lint's missing-dependency error), and regenerate `router.g.dart` in the same commit. `settings_screen_test.dart`'s two `@Dependencies` lists gain `backupFrequency` and `backupLastBackupAt` too (commit 10).

### Screen tree (`backup_screen.dart`, one view file with private widgets)

```text
@Dependencies([BackupController, backupAccount, backupFrequency])
BackupScreen (ConsumerWidget)
  PopScope(canPop: switch (state) { BackupWorking(job: BackupJob.restore) => false, _ => true })
    Scaffold(appBar: backupTitle)
      restoring            → Center: spinner + backupRestoring
      account loading      → Center: spinner
      account error BackupException(failure: notAuthorized)
                           → _NotConnectedBody(reconnect: true)
      account other error  → padded backupLoadFailed, the failure message slot (leaving out notAuthorized),
                             TextButton(backupRetry → ref.invalidate(backupAccountProvider)), TextButton(backupDisconnect)
      account null         → _NotConnectedBody(reconnect: false)
      account data         → _ConnectedBody
```

- **`_NotConnectedBody`** is a `ListView` with 24px padding, like the export screen's body: `backupIntro`, `backupScopeNote`, `backupPrivacyNote` (`bodyLarge`), then a `FilledButton` (key `backupConnectButton`). With `reconnect` (this device is connected, but the account check failed: no grant here, or another account's token), `backupReconnectNeeded` sits above the button, the button reads `backupReconnect`, and a `TextButton(backupDisconnect)` sits under it; otherwise the button reads `backupConnect`. Either way the `FilledButton` calls `_connect` (below). The frequency plays no part in this choice; the screen watches `backupFrequencyProvider` only for the radio. Under the buttons, the failure message slot, which leaves out `notAuthorized` (the body already offers Connect or Reconnect). Frequency, Back up now and the list stay hidden until an account is connected.
- **`_ConnectedBody`** is a `CustomScrollView`, like `_PreviewBody` in `csv_import_screen.dart`:
  1. `SliverToBoxAdapter`: padded `backupIntro` and `backupPrivacyNote`.
  2. `CsvImportSectionHeader(title: l10n.backupSectionAccount)`, then `ListTile(key: backupAccountTile, title: email, trailing: TextButton(backupDisconnect))`.
  3. `CsvImportSectionHeader(title: l10n.backupSectionAutomatic)`, then `RadioGroup<BackupFrequency>(groupValue: frequency, onChanged: (f) { if (f != null) unawaited(controller.setFrequency(f)); })` around three `RadioListTile` rows, and the caption `backupAutomaticNote`. `frequency` is `ref.watch(backupFrequencyProvider).value ?? BackupFrequency.off`.
  4. Padded `FilledButton(key: backupNowButton)` with the export screen's 20px spinner pattern while `working(backup)`. Under it, the "last backup" line from the first backup with `isThisDevice`: `backupLastBackup(date, sizeMb)`, or `backupNoBackupYet`. Then one message slot: `backupBackingUp` while `working(backup)`, else the failure text. When the state is `failed(notAuthorized)`, the slot shows `backupReconnectNeeded` followed by `TextButton(key: backupReconnectButton, backupReconnect)`, which calls `_connect`.
  5. `CsvImportSectionHeader(backupSectionList)`, then `backupListEmpty`, or `SliverList.builder` of `_BackupEntryTile`, newest first. The row count grows with the number of devices, so it is never a `Column`.
  6. `SliverToBoxAdapter(SizedBox(height: 24))`.
- **`_BackupEntryTile`** (key `ValueKey('backupEntry:${b.id}')`): the title is `DateHelpers.formatDisplayDateTime(b.createdAt.toLocal(), locale)`. The subtitle is `"${b.isThisDevice ? '${l10n.backupThisDevice} · ' : ''}${l10n.backupEntryDetails(platform, b.appVersion, sizeMb)}"`, plus a second line `backupEntryNeedsUpdate` when `!b.restorable`. `platform` is `Android` or `iOS` (proper nouns, not localized), from a private `_platformLabel(String)` that the restore offer also calls. The trailing `PopupMenuButton<_EntryAction>` (key `backupEntry:<id>:menu`, the `account_tile.dart` pattern) holds Restore (left out when `!restorable`) and Delete (`commonDelete`).
- **Confirms** use `showConfirmDialog` and, except the restore offer (see `_connect`), check `context.mounted` after the `await`:
  - Restore: title `backupRestoreConfirmTitle`, body `backupRestoreConfirmBody(date)`, confirm `backupRestore`.
  - Delete: title `backupDeleteConfirmTitle`, body `backupDeleteConfirmBody(date)`, confirm `commonDelete`. No undo snackbar: a Drive delete is permanent, so the confirm takes its place. Both the Restore and Delete confirms pass `tonal: true`, as the category and account deletes do.
  - Disconnect: title `backupDisconnectConfirmTitle`, body `backupDisconnectConfirmBody` (this device only; other devices and the Drive backups are not affected; the Google Account's third-party connections page removes access everywhere), confirm `backupDisconnect`. The connected body, the reconnect body and the load-failed body each have a Disconnect button that opens it and then calls `disconnect`: an email is stored in all three (D-19), and Disconnect needs no token or network (D-16).
  - Restore offer: title `backupRestoreOfferTitle`, body `backupRestoreOfferBody(date, platform, version)`, confirm `backupRestore`. Cancel is `showConfirmDialog`'s `commonCancel`; it takes no custom cancel label, and none is added for one caller.
  - Restore and Delete pass `tonal: true`, like the category and account deletes; no new parameter is needed (AGENTS.md).
- **`_connect` and the restore offer (D-25).** A private function that both the Connect/Reconnect `FilledButton` and the Reconnect `TextButton` call. It awaits the command's result and checks `context.mounted` once, before it opens the dialog, as `transaction_form_screen.dart` does after `resolveCategoryChipTap()` before it opens a picker. It does not check again after the dialog. `_run` invalidated `backupAccountProvider` when `connect()` ended, and when the account reloads, usually while the dialog is open, the screen replaces the body that owns `context` (`_NotConnectedBody` becomes `_ConnectedBody`). A second check would then drop the Restore tap. Nothing after the dialog uses `context`, and `controller` is read before the first `await`:

  ```dart
  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(backupControllerProvider.notifier);
    final offer = await controller.connect();
    if (offer == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.backupRestoreOfferTitle,
      body: l10n.backupRestoreOfferBody(
        DateHelpers.formatDisplayDateTime(offer.createdAt.toLocal(), locale),
        _platformLabel(offer.platform),
        offer.appVersion,
      ),
      confirmLabel: l10n.backupRestore,
    );
    if (confirmed) await controller.restore(offer);
  }
  ```

  Restore takes the same path as the list's Restore. Cancel does nothing, and the backup stays in the list. The offer comes only from a tap, never at launch, on screen open or from an automatic backup (D-5).
- **Size:** a private `String _sizeMb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);`, the expression `new_version_badge.dart` uses inline. A shared helper would not shrink the code.
- **Reuse:** `CsvImportSectionHeader` is reused across sub-slices instead of copied. Renaming it to a neutral shared name is a separate cleanup. The restoring body repeats the ~10-line shape of `csv_import_screen.dart`'s private `_Progress`; a shared widget would not shrink the code.

### State → render

| Situation                                                 | Render                                                                                                                                                                                                                                                                                                                                     |
|-----------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `backupAccount` loading                                   | Centred spinner.                                                                                                                                                                                                                                                                                                                           |
| `backupAccount` error other than `notAuthorized`          | `backupLoadFailed`, the failure message slot (leaving out `notAuthorized`), Retry and Disconnect. A command that failed offline shows its `backupFailedNoNetwork` here, because the account reload after it fails too (AC8).                                                                                                           |
| `backupFrequency` loading or error                        | Read as `ref.watch(backupFrequencyProvider).value ?? BackupFrequency.off`.                                                                                                                                                                                                                                                                 |
| `backupAccount` null (not connected)                      | Intro, scope note, privacy note, Connect. A cancel of the account picker (`authenticate`) returns here with no message. On Android, cancelling the Drive consent step (`authorizeScopes`) arrives as `GoogleSignInExceptionCode.unknownError` ("SDK reported an exception: …"), not `canceled`, so it shows `errorSnackbarGeneric` (S3-g). |
| `backupAccount` error `BackupException(notAuthorized)`    | Same, with `backupReconnectNeeded`, Reconnect in place of Connect, and Disconnect.                                                                                                                                                                                                                                                         |
| Connect or Reconnect returns a backup (D-25)              | The restore offer dialog. Restore calls `restore(offer)`, so the screen turns to `working(restore)` below; Cancel does nothing.                                                                                                                                                                                                            |
| Connected, `idle`                                         | Every section enabled.                                                                                                                                                                                                                                                                                                                     |
| `working(backup)`                                         | Back up now shows its spinner, the slot reads "Backing up…", Disconnect and the row menus are disabled. Back still works: the `keepAlive` controller keeps uploading.                                                                                                                                                                      |
| `working(connect / disconnect / delete)`                  | Actions disabled; back allowed.                                                                                                                                                                                                                                                                                                            |
| `working(restore)`                                        | The body becomes the restoring progress and `PopScope` blocks back. On success the app restarts; on failure the screen returns with the message.                                                                                                                                                                                           |
| `failed(noNetwork / storageFull / newerSchema / corrupt)` | The slot shows the matching `backupFailed…` text.                                                                                                                                                                                                                                                                                          |
| `failed(notAuthorized)`                                   | Connected body: the slot shows `backupReconnectNeeded` and a Reconnect `TextButton` that calls `_connect`. The not-connected body leaves it out of its slot (the body already offers Connect or Reconnect).                                                                                                                                |
| `failed(unknown)`                                         | The slot shows `errorSnackbarGeneric`.                                                                                                                                                                                                                                                                                                     |

Failures map through one top-level `String _failureMessage(BackupFailure f, AppLocalizations l10n)` switch, as in `csv_import_screen.dart`. The radio is disabled while any job is working (wrap the `RadioGroup` in `IgnorePointer` while `state is BackupWorking`, since `RadioGroup.onChanged` cannot be null), and `BackupController.setFrequency` ignores a call while the state is `BackupWorking`: otherwise a tap during `working(disconnect)` can store `daily` after the disconnect stored `off`, leaving a disconnected device with automatic backup on and an overdue subtitle. Add a controller test for that ignore.

---

## Error Handling

`BackupRepository` maps errors in one place, `_mapDio(token, body)`, used by every call to Drive, including the account check in `_token()`. `disconnect()` makes no network request. `GoogleSignInException` with code `canceled` on Connect is not a failure: `connect()` returns null. On Android only a cancel of the account picker (`authenticate`) arrives as `canceled`; cancelling the Drive consent step (`authorizeScopes`) arrives as `unknownError` and shows `errorSnackbarGeneric`. Everything that reaches `BackupController._run` as something other than `BackupException` becomes `failed(unknown)`, logged as `${e.runtimeType}` only.

| Failure                                                                                                                                                                            | `BackupFailure` | User sees                                                                                                   | Drive                                                                                                                                                                                                            | Local                                                                                                                                                                                                                                                     |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------|-------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `DioException` of type `connectionTimeout`, `sendTimeout`, `receiveTimeout` or `connectionError`                                                                                   | `noNetwork`     | `backupFailedNoNetwork`                                                                                     | Previous backup kept.                                                                                                                                                                                            | Snapshot or download deleted; database untouched.                                                                                                                                                                                                         |
| HTTP 403 whose body has `error.errors[*].reason == 'storageQuotaExceeded'` (on the `POST` or the `PUT`)                                                                            | `storageFull`   | `backupFailedStorageFull`                                                                                   | Previous backup kept.                                                                                                                                                                                            | Snapshot deleted.                                                                                                                                                                                                                                         |
| Drive `about.get` returns a `user` without `emailAddress` (Google documents it as output-only) | `unknown` | `errorSnackbarGeneric`; S3-b records the observed shape and the userinfo fallback (S3-b) | Unchanged; nothing is listed, written or deleted with that token. | Unchanged; no snapshot written. |
| Silent token is null (the grant was revoked, or the database was copied from another phone)                                                                                        | `notAuthorized` | Reconnect body, or `backupReconnectNeeded` and Reconnect in the slot                                        | Unchanged.                                                                                                                                                                                                       | Unchanged; no snapshot written.                                                                                                                                                                                                                           |
| The silent token's account (Drive `about.get` `user.emailAddress`) is not `backup_account_email`, ignoring case (D-19, S3-a)                                                       | `notAuthorized` | Same                                                                                                        | Unchanged; nothing is listed, written or deleted with that token.                                                                                                                                                | Unchanged; no snapshot written.                                                                                                                                                                                                                           |
| Silent token request throws (Android `GoogleSignInException(unknownError)` "Authorization failed: …", iOS `PlatformException`), e.g. offline after the cached token expired (S3-f) | `unknown`       | `errorSnackbarGeneric`                                                                                      | Unchanged.                                                                                                                                                                                                       | Unchanged; no snapshot written.                                                                                                                                                                                                                           |
| HTTP 401                                                                                                                                                                           | `notAuthorized` | Same. The repository first calls `_auth.clearToken(token)`, so the next try asks the SDK for a fresh token. | Unchanged.                                                                                                                                                                                                       | Unchanged.                                                                                                                                                                                                                                                |
| Restore: the file's `user_version` is above `schemaVersion`                                                                                                                        | `newerSchema`   | `backupFailedNewerSchema`                                                                                   | Unchanged.                                                                                                                                                                                                       | `.part` deleted; database untouched.                                                                                                                                                                                                                      |
| Any check fails: `ATTACH`/`PRAGMA` error, `quick_check` not `ok`, `user_version` < 1, a snapshot whose version is not `schemaVersion`, or an uploaded size that differs            | `corrupt`       | `backupFailedCorrupt`                                                                                       | Previous backup kept; a bad upload is deleted by id. If that delete fails, the file becomes a false clone: `last_backup_at` was not written, so the next backup takes a new id and prunes nothing (see [Risks](#risks--known-limitations)).                                                                                                      | Temp file deleted; database untouched.                                                                                                                                                                                                                    |
| Restore: migrating an older staged copy throws                                                                                                                                     | `unknown`       | `errorSnackbarGeneric`                                                                                      | Unchanged.                                                                                                                                                                                                       | `.part` deleted; database untouched.                                                                                                                                                                                                                      |
| Delete returns 404 (already gone)                                                                                                                                                  | none            | The list refreshes without it.                                                                              | Gone.                                                                                                                                                                                                            | Unchanged.                                                                                                                                                                                                                                                |
| Disconnect: `GoogleSignIn.signOut()` throws (on Android, `clearCredentialStateAsync` fails as `PlatformException` "Clear Failed")                                                  | `unknown`       | `errorSnackbarGeneric` on the not-connected body                                                            | Unchanged.                                                                                                                                                                                                       | Disconnected anyway: the email and frequency writes come first.                                                                                                                                                                                           |
| Connect: listing the account for the restore offer fails                                                                                                                           | as mapped above | The matching message                                                                                        | Unchanged.                                                                                                                                                                                                       | Connected: the email is stored; no offer.                                                                                                                                                                                                                 |
| Any other HTTP status (403 rate limits, 404 on download, 429, 5xx)                                                                                                                 | `unknown`       | `errorSnackbarGeneric`                                                                                      | Previous backup kept.                                                                                                                                                                                            | Temp file deleted.                                                                                                                                                                                                                                        |
| `FileSystemException` (disk full writing the snapshot or the download)                                                                                                             | `unknown`       | `errorSnackbarGeneric`                                                                                      | Previous backup kept.                                                                                                                                                                                            | Temp file deleted.                                                                                                                                                                                                                                        |
| `GoogleSignInException` other than `canceled` (for example `clientConfigurationError`, `uiUnavailable`)                                                                            | `unknown`       | `errorSnackbarGeneric`                                                                                      | Unchanged.                                                                                                                                                                                                       | Unchanged.                                                                                                                                                                                                                                                |
| Process killed during a backup                                                                                                                                                     | none            | Nothing.                                                                                                    | Previous backup kept; an unfinished resumable session expires after a week. If the upload had finished, the new file stays too, and the next backup treats it as a clone's ([Risks](#risks--known-limitations)). | `<cache>/ledgerly-backup.sqlite` is deleted before the next `VACUUM INTO`.                                                                                                                                                                                |
| Process killed during a restore download, the identity write or the migration                                                                                                      | none            | Nothing.                                                                                                    | Unchanged.                                                                                                                                                                                                       | `.restore.part` and any `.restore.part-journal` stay until the next restore deletes both before downloading; bootstrap ignores them. A stale hot journal left in place would be rolled into the next download on `ATTACH` and corrupt or silently mix it. |
| Process killed after staging, or during the restart                                                                                                                                | none            | The next cold start opens the restored data.                                                                | Unchanged.                                                                                                                                                                                                       | `applyStagedRestore` finishes the swap.                                                                                                                                                                                                                   |

No retry loop and no backoff (D-22). Every command invalidates `backupAccountProvider` when it ends (success or failure) while the controller is still mounted, so the list always shows what Drive holds; the Drive listing is the source of truth, not `last_backup_at` (PRD.md:1043).

---

## Architecture

### Layer placement

| Layer          | File                                                                                | New / changed | Contents                                                                                                                                                                                                                                 |
|----------------|-------------------------------------------------------------------------------------|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Domain model   | `lib/domain/models/drive_backup.dart`                                               | new           | `BackupFrequency`, `BackupFailure`, `BackupException`, the `DriveBackup` and `BackupAccount` record typedefs. No codegen: records have structural `==`.                                                                                  |
| Service        | `lib/data/services/database_file_service.dart`                                      | new           | Owns every database file path. `lib/app/` may not import `path_provider`, so bootstrap swaps the file through this service.                                                                                                              |
| Service        | `lib/data/services/google_auth_service.dart`                                        | new           | Wraps `google_sign_in` 7.x. The only `lib/` importer of `google_sign_in` besides `service_providers.dart`.                                                                                                                               |
| Service        | `lib/data/services/google_drive_service.dart`                                       | new           | Drive v3 REST over the shared `Dio`. Returns records and throws `DioException`, like `ExchangeRateService`.                                                                                                                              |
| Repository     | `lib/data/repositories/user_preferences_repository.dart`                            | changed       | The four backup keys.                                                                                                                                                                                                                    |
| Repository     | `lib/data/repositories/backup_repository.dart`                                      | new           | Snapshot, checks, upload, pruning, listing, download, staging, due check. No use case: it is the one repository involved (PRD.md:1032); it takes `UserPreferencesRepository` as `DriftAccountTypeRepository` takes `CurrencyRepository`. |
| Providers      | `lib/app/providers/service_providers.dart`                                          | changed       | `googleAuthServiceProvider`.                                                                                                                                                                                                             |
| Providers      | `lib/app/providers/repository_providers.dart`                                       | changed       | `backupRepositoryProvider`.                                                                                                                                                                                                              |
| Providers      | `lib/app/providers/app_restart_provider.dart`                                       | new           | `appRestartProvider`, a required override like `appDatabaseProvider`.                                                                                                                                                                    |
| App            | `lib/app/bootstrap.dart`                                                            | changed       | The swap in `bootstrap()`'s `openDatabase`; the `start()` split and the restart override in `bootstrapFor`.                                                                                                                              |
| App            | `lib/app/app.dart`                                                                  | changed       | The automatic trigger: first frame and `AppLifecycleListener(onShow:)`.                                                                                                                                                                  |
| Route          | `lib/app/router.dart`                                                               | changed       | `/settings/backup`; three names in `routerProvider`'s `dependencies`.                                                                                                                                                                    |
| Core           | `lib/core/utils/date_helpers.dart`                                                  | changed       | `formatDisplayDateTime`, cached per locale.                                                                                                                                                                                              |
| State          | `lib/ui/features/settings/backup/view_models/backup_state.dart`                     | new           | `BackupJob` and the sealed `BackupState`.                                                                                                                                                                                                |
| Controller     | `lib/ui/features/settings/backup/view_models/backup_controller.dart`                | new           | `keepAlive`, not a family, so an upload survives leaving the screen.                                                                                                                                                                     |
| Providers      | `lib/ui/features/settings/backup/view_models/backup_providers.dart`                 | new           | `backupAccountProvider`, `backupFrequencyProvider`, `backupLastBackupAtProvider` (all auto-dispose).                                                                                                                                                                  |
| View           | `lib/ui/features/settings/backup/views/backup_screen.dart`                          | new           | The screen and its private widgets.                                                                                                                                                                                                      |
| Settings entry | `lib/ui/features/settings/views/settings_screen.dart`                               | changed       | The tile.                                                                                                                                                                                                                                |
| Layer rules    | `import_analysis_options.yaml`, `test/unit/architecture/layer_boundaries_test.dart` | changed       | `google_sign_in` joins the plugin bans.                                                                                                                                                                                                  |
| Platform       | `ios/Runner/Info.plist`                                                             | changed       | `GIDClientID`, `CFBundleURLTypes`.                                                                                                                                                                                                       |

### Domain model

```dart
// lib/domain/models/drive_backup.dart
enum BackupFrequency { off, daily, weekly }

enum BackupFailure { noNetwork, storageFull, notAuthorized, newerSchema, corrupt, unknown }

/// Thrown by BackupRepository; the controller and the screen switch on
/// [failure], as csv_import.dart's CsvFileException carries CsvFileErrorKind.
class const BackupException(final BackupFailure failure) implements Exception;

/// One backup file in the connected account's appDataFolder.
typedef DriveBackup = ({
  String id,
  /// appProperties device_id of the device that made the file.
  String deviceId,
  DateTime createdAt, // UTC, from appProperties created_at
  String platform, // 'android' or 'ios'
  String appVersion,
  int sizeBytes,
  bool isThisDevice,
  bool restorable, // schema_version <= the app's schemaVersion (computed in the repository)
});

/// The connected account: its email and every backup in it, newest first.
typedef BackupAccount = ({String email, List<DriveBackup> backups});
```

### `UserPreferencesRepository` additions

Following the existing `get`/`set`/`watch` style and the private `_kXxx` key constants:

```dart
// ---------- Cloud backup (PRD → Cloud Backup) ----------
Stream<BackupFrequency> watchBackupFrequency();
Future<BackupFrequency> getBackupFrequency(); // default off
Future<void> setBackupFrequency(BackupFrequency frequency);

/// UTC: this device's last backup, or its last restore (D-15). Null before either.
Future<DateTime?> getLastBackupAt();
Future<void> setLastBackupAt(DateTime at);
Stream<DateTime?> watchLastBackupAt(); // the Settings tile only (D-26)

/// Null until the first backup or restore writes one.
Future<String?> getDeviceId();
Future<void> setDeviceId(String id);

/// The Google account connected on this device (D-19). Null when not connected.
Future<String?> getBackupAccountEmail();
Future<void> setBackupAccountEmail(String? email);
```

- Keys: `_kBackupFrequency = 'backup_frequency'`, `_kLastBackupAt = 'last_backup_at'`, `_kDeviceId = 'device_id'`, `_kBackupAccountEmail = 'backup_account_email'`.
- `backup_frequency` stores `frequency.name` and decodes with `BackupFrequency.values.byName(_decodeAs<String>(v))`, like `_decodeThemeMode`. An unknown name becomes `PreferenceDecodeException`.
- `last_backup_at` stores `at.toUtc().toIso8601String()` and decodes with `_decodeNullableDate('last_backup_at')`, whose `DateTime.parse` of a `Z` string reads back as UTC.
- `device_id` decodes with `_decodeAs<String?>`.
- `backup_account_email` follows the file's nullable-key pattern, as `getDefaultAccountId`/`setDefaultAccountId(int? id)` do: `_readJson<String?>(defaultValue: null, decode: _decodeAs<String?>)`, and `_writeJson(_kBackupAccountEmail, email)`. A null writes the JSON `null` (the row stays, as `setLocale(null)` leaves it), which reads back as null.
- `Stream<DateTime?> watchLastBackupAt()` feeds only the Settings tile's overdue subtitle (D-26). The automatic trigger never watches it, so its write still starts nothing (Deviation 13). No watcher for `device_id` or `backup_account_email` (`account()` reads it), and no clear method: nothing needs them.

### Services

```dart
// lib/data/services/database_file_service.dart
class const DatabaseFileService({
  final Future<Directory> Function() documentsDirectory = getApplicationDocumentsDirectory,
  final Future<Directory> Function() temporaryDirectory = getTemporaryDirectory,
}) {
  /// `<documents>/ledgerly.sqlite`, the file bootstrap opens.
  Future<String> databasePath();

  /// `<cache>/ledgerly-backup.sqlite`, deleted first if left over.
  Future<File> snapshotFile();

  /// `<documents>/ledgerly.sqlite.restore.part`, where a restore downloads,
  /// after deleting any leftover `.part` and `ledgerly.sqlite.restore.part-journal`.
  Future<File> restoreDownloadFile();

  /// Renames the checked `.restore.part` to `ledgerly.sqlite.restore`.
  Future<void> stageRestore();

  /// Bootstrap, before the database is constructed: see Restore flow.
  Future<void> applyStagedRestore();
}
```

The directory getters default to the `path_provider` functions as `const` tear-offs, so `bootstrap()` can write `const DatabaseFileService()`. `AppReleaseService` and `CsvFileService` inject the same getters, but as nullable parameters filled by `?? getTemporaryDirectory`; this service uses the tear-offs as default values instead, so that it can be `const`. Paths are joined with `'${dir.path}/…'`, because `path` is not a direct dependency.

```dart
// lib/data/services/google_auth_service.dart
class GoogleAuthService(final GoogleSignIn _signIn) {
  static const _scopes = ['https://www.googleapis.com/auth/drive.appdata'];
  static const _webClientId = '…'; // P1 Web client ID (D-23); Android's serverClientId

  // initialize() must run exactly once per process, including across the
  // in-process restart that builds a new container and a new service.
  // Keyed by the GoogleSignIn object; production has one, GoogleSignIn.instance.
  static final _initialized = Expando<Future<void>>();
  Future<void> _ready() =>
      _initialized[_signIn] ??= _signIn.initialize(serverClientId: _webClientId);

  /// From a user tap only. Returns the picked account's email once the scope
  /// is granted, or null when the user cancels the account picker. On Android
  /// a cancelled consent step rethrows (unknownError).
  Future<String?> connect();   // account = authenticate(scopeHint: _scopes), then
                               // account.authorizationClient.authorizeScopes(_scopes);
                               // return account.email;
                               // GoogleSignInExceptionCode.canceled → null

  /// No UI. Null when there is no grant. Names no account (D-19).
  Future<String?> accessToken(); // _signIn.authorizationClient.authorizationForScopes(_scopes)?.accessToken

  /// After a 401: drops the cached token so the next call gets a fresh one.
  Future<void> clearToken(String token); // authorizationClient.clearAuthorizationToken(accessToken: token)

  /// This device only: clears the SDK's sign-in state and revokes nothing (D-16).
  Future<void> signOut();      // _signIn.signOut()
}
```

- `connect()` returns `account.email` from `authenticate()`. Its token is bound to the picked account on both platforms: `account.authorizationClient` passes the account's email on Android (`setAccount`) and its user id on iOS. The email is non-null by type; the native layers put `""` there only for an ID token without an email claim, and Sign in with Google tokens carry one in practice.
- `accessToken()` uses `GoogleSignIn.instance.authorizationClient`, which names no account: on Android the native `AuthorizationClient` then uses the app's default account, which the last Connect set; on iOS the plugin restores the one keychain user, who is the last account to sign in. The public API has no silent call that names an account, so the repository checks the token's account (D-19).
- `signOut()` keeps the grant. The CredentialManager docs say Android's `clearCredentialState` clears the stored credential session; GIDSignIn documents iOS's `signOut` as removing the keychain user, and only `disconnect()` revokes the OAuth grants. It also clears Android's default account and the iOS keychain session, so the next `connect()` shows the account picker (on iOS, Google's sign-in page decides whether to show its chooser; S3-c). On Android it can throw a `PlatformException` ("Clear Failed"). The service makes no HTTP request, so it takes no `Dio`.
- The constructor has no side effects. `initialize` runs on the first call, so a launch with `backup_frequency` off never touches the plugin. That also means a misconfigured iOS client ID, which crashes natively since `google_sign_in_ios` 6.3.7, crashes only on a backup path, not at startup.

```dart
// lib/data/services/google_drive_service.dart
typedef DriveFile = ({String id, int size, Map<String, String> appProperties});

class GoogleDriveService(final Dio _dio) {
  static const _files = 'https://www.googleapis.com/drive/v3/files';
  static const _upload = 'https://www.googleapis.com/upload/drive/v3/files';

  /// GET .../drive/v3/about?fields=user(emailAddress): the token's account,
  /// for the account check (D-19).
  Future<String> accountEmail(String token);

  /// GET _files with spaces=appDataFolder,
  /// fields=nextPageToken,files(id,size,appProperties), pageSize=1000; repeats
  /// with pageToken until nextPageToken is absent (a page may hold fewer than
  /// pageSize files even when more exist). `size` arrives as a JSON string
  /// (int64), so int.tryParse; entries without an id or a size are skipped.
  Future<List<DriveFile>> list(String token);

  /// POST _upload?uploadType=resumable&fields=id,size with JSON
  /// {name: 'ledgerly.sqlite', parents: ['appDataFolder'], appProperties},
  /// X-Upload-Content-Type: application/vnd.sqlite3 and X-Upload-Content-Length;
  /// then one PUT to the Location header with file.openRead() and
  /// Content-Length. The final PUT returns the files resource; `fields` is a
  /// `files.create` parameter, so it belongs on the POST. Keep
  /// GET files/{id}?fields=size as the fallback when the response has no size.
  Future<({String id, int size})> upload(String token, File file, Map<String, String> appProperties);

  /// _dio.download('$_files/$id', path, queryParameters: {'alt': 'media'}, deleteOnError: true)
  Future<void> download(String token, String id, String path);

  /// DELETE '$_files/$id'. A 404 counts as deleted (validateStatus).
  Future<void> delete(String token, String id);
}
```

- Every request sends `Options(headers: {'Authorization': 'Bearer $token'})`. Never an `access_token` query parameter, and never an interceptor on the shared `Dio`, which would also send the Google token with the FX and GitHub requests.
- JSON is parsed with switch/case map patterns, as `AppReleaseService` does.
- Two plain requests for the upload: no `multipart/related` body to build and no resume logic.

### Repository

```dart
// lib/data/repositories/backup_repository.dart
class BackupRepository(
  final AppDatabase _db,
  final UserPreferencesRepository _prefs,
  final GoogleAuthService _auth,
  final GoogleDriveService _drive,
  final DatabaseFileService _files, {
  required final Future<String> Function() appVersion,
  final DateTime Function() clock = DateTime.now,
}) {
  /// Null when this device is not connected, with no plugin call. Throws
  /// BackupException(notAuthorized) when the account check fails, and
  /// other BackupExceptions when Drive fails.
  Future<BackupAccount?> account();
  /// Null when the picker is cancelled or there is nothing to offer (D-25).
  Future<DriveBackup?> connect();
  Future<void> disconnect();              // no network; see below (D-16)
  Future<bool> isDue();                   // preferences only; see Automatic backup
  Future<void> backUp();                  // see Backup flow
  Future<void> stageRestore(DriveBackup b); // see Restore flow
  Future<void> delete(DriveBackup b);
}
```

- **`_token()`**, the account check (D-19). Every command that needs a token starts with it: `account()`, `backUp()`, `stageRestore()` and `delete()`. It reads `backup_account_email`; null → `BackupException(notAuthorized)` with no plugin call. Otherwise `_auth.accessToken()`; null → `notAuthorized`. Otherwise it calls `_drive.accountEmail(token)` inside `_mapDio` and compares the result with the stored email, ignoring case; a different email → `notAuthorized`. It returns the token. The check costs each of these commands one `about.get` GET.
- `account()`: stored email null → null, without touching the plugin. Otherwise `_token()`, then `list`, one after the other: the list must not run with another account's token, and `(a, b).wait` would wrap a `DioException` in `ParallelWaitError` and skip the mapping. The `email` it returns is the stored one. Each file becomes a `DriveBackup` when its keys parse, keeping its appProperties `device_id` as `deviceId`; `isThisDevice` compares `deviceId` with `getDeviceId()`; the list is sorted by `createdAt` descending.
- `connect()` (D-25): `email = await _auth.connect()`; null (picker cancelled) → return null, writing nothing. Otherwise `setBackupAccountEmail(email)`, then `account()!` (the email was just written) and `getLastBackupAt()`. It returns the first, that is newest, backup if it is `restorable` and either was created after `last_backup_at`, or `last_backup_at` is null and `await _db.transactions.count().getSingle() == 0`; otherwise null. It does not look past a newest backup that is not restorable. A Drive failure in the listing throws as usual, and the email stays stored.
- `disconnect()` (D-16): `setBackupAccountEmail(null)`, `setBackupFrequency(off)`, then `_auth.signOut()`. No network. The local writes come first, because `signOut()` can throw on Android ("Clear Failed"): the device is then disconnected anyway, and once the stored email is null nothing calls the plugin silently.
- `appVersion` and `clock` follow `appUpdateRepository`'s `installedVersion` closure and the repositories' `clock` precedent. Production passes `appVersion`.

### Providers

```dart
// service_providers.dart — the only lib/app file allowed to import google_sign_in
@Riverpod(keepAlive: true)
GoogleAuthService googleAuthService(Ref ref) =>
    GoogleAuthService(GoogleSignIn.instance);

// repository_providers.dart
@Riverpod(keepAlive: true, dependencies: [appDatabase, userPreferencesRepository])
BackupRepository backupRepository(Ref ref) {
  final packageInfo = ref.watch(packageInfoServiceProvider);
  return BackupRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(userPreferencesRepositoryProvider),
    ref.watch(googleAuthServiceProvider),
    GoogleDriveService(ref.watch(dioProvider)),
    const DatabaseFileService(),
    appVersion: () async => (await packageInfo.read()).version,
  );
}

// app_restart_provider.dart
/// Rebuilds the app on a fresh database and container. Overridden by
/// bootstrapFor; only a restore calls it.
@Riverpod(keepAlive: true, dependencies: [])
Future<void> Function() appRestart(Ref ref) => throw UnimplementedError(
  'appRestartProvider must be overridden by bootstrap()',
);

// backup_providers.dart
@Riverpod(dependencies: [backupRepository])
Future<BackupAccount?> backupAccount(Ref ref) =>
    ref.watch(backupRepositoryProvider).account();

@Riverpod(dependencies: [userPreferencesRepository])
Stream<BackupFrequency> backupFrequency(Ref ref) =>
    ref.watch(userPreferencesRepositoryProvider).watchBackupFrequency();

@Riverpod(dependencies: [userPreferencesRepository])
Stream<DateTime?> backupLastBackupAt(Ref ref) =>
    ref.watch(userPreferencesRepositoryProvider).watchLastBackupAt();
```

`GoogleDriveService` and `DatabaseFileService` get no providers: repository tests construct `BackupRepository` with mocks, and controller and widget tests override `backupRepositoryProvider`. `googleAuthService` gets one only because `repository_providers.dart` may not import `google_sign_in`.

### State and controller

```dart
// backup_state.dart
enum BackupJob { connect, disconnect, backup, restore, delete }

@freezed
sealed class BackupState with _$BackupState {
  const factory BackupState.idle() = BackupIdle;
  const factory BackupState.working(BackupJob job) = BackupWorking;
  /// The last command failed. Stays until the next command starts.
  const factory BackupState.failed(BackupFailure failure) = BackupFailed;
}

// backup_controller.dart
@Riverpod(
  keepAlive: true,
  dependencies: [backupRepository, userPreferencesRepository, backupAccount, appRestart],
)
class BackupController extends _$BackupController {
  @override
  BackupState build() => const BackupState.idle();

  /// The restore offer (D-25), or null on cancel, failure, an ignored
  /// command, or nothing to offer.
  Future<DriveBackup?> connect() =>
      _run<DriveBackup?>(BackupJob.connect, (repo) => repo.connect());
  Future<void> disconnect() => _run(BackupJob.disconnect, (repo) => repo.disconnect());
  Future<void> backUpNow() => _run(BackupJob.backup, (repo) => repo.backUp());
  Future<void> delete(DriveBackup b) => _run(BackupJob.delete, (repo) => repo.delete(b));
  Future<void> restore(DriveBackup b) {
    final restart = ref.read(appRestartProvider);
    return _run(BackupJob.restore, (repo) async {
      await repo.stageRestore(b);
      await restart();
    });
  }
  // Prefs write. Returns without writing while the state is BackupWorking
  // (the radio is disabled then; this is the programmatic guard). A throw
  // sets failed(unknown) only when the state is not BackupWorking, so a
  // running job keeps its state and its guard.
  Future<void> setFrequency(BackupFrequency f);
  Future<void> backUpIfDue({required Future<void> after}); // see Automatic backup

  /// Ignores a command while one is working. Maps BackupException to its
  /// failure and anything else to unknown (logging only the runtimeType),
  /// then returns at once if !ref.mounted, writing neither the state nor
  /// ref.invalidate(backupAccountProvider) (both throw UnmountedRefException
  /// on a disposed ref). Otherwise it writes the state and invalidates
  /// backupAccountProvider so the screen re-reads Drive. Returns the body's
  /// result on success, and null when the command is ignored or fails.
  Future<T?> _run<T>(BackupJob job, Future<T> Function(BackupRepository repo) body);
}
```

- `BackupException` comes from the domain model (Deviation 3), so the screen can match a `notAuthorized` error of `backupAccountProvider` without importing `data/`.
- `connect()` is the only command whose result the screen reads. It names `T` explicitly: from the `Future<DriveBackup?>` context alone, Dart infers `T` = `DriveBackup` and then rejects the closure's `Future<DriveBackup?>` (`return_of_invalid_type_from_closure`). The other commands keep `Future<void>` and need no type argument: with `T` = `void`, the method's `T?` normalises to `void`, so the call still satisfies `Future<void>`.
- The working guard is the single owner of "already requested": first frame, `onShow`, "Back up now", Restore and Delete all go through `_run`, so a backup and a prune can never overlap. No second single-flight in the repository.
- A `restart()` that throws after the old tree is gone is caught by `_run`, logged as its runtime type, and neither writes state nor invalidates (`ref.mounted` is false).
- Restore is refused while a backup runs (the guard), so the restart never closes the shared `Dio` under an upload.
- Copy the final `@Dependencies` names from `riverpod_lint`'s "Missing dependencies" message.

### Bootstrap and App

```dart
// bootstrap.dart
@Dependencies([router, exchangeRateRepository]) // plus what riverpod_lint asks for once App reads BackupController
Future<void> bootstrap() => bootstrapFor(
  openDatabase: () async {
    const files = DatabaseFileService();
    await files.applyStagedRestore();
    return AppDatabase(
      driftDatabase(
        name: 'ledgerly',
        native: DriftNativeOptions(databasePath: files.databasePath),
      ),
    );
  },
  localeService: const LocaleService(),
);
```

- `DriftNativeOptions(databasePath:)` makes `DatabaseFileService` the one source of the path. It resolves to the same `<documents>/ledgerly.sqlite` that `drift_flutter` 0.3.1 uses by default, so no data moves.
- `bootstrapFor` keeps its signature and test seam. Step 1 stays outside `start()`; steps 2–7 move into it, with step 2 becoming `db = await openDatabase();` on a `late AppDatabase db;` declared at `bootstrapFor` scope: the restart closure awaits `db.close()` and `start()` must reassign that variable, or a second restart would close an already-closed database and throw drift's `StateError`. `(runAppFn ?? runApp)` becomes a local `launch`, and the overrides list gains `appRestartProvider.overrideWithValue(...)`. The re-indent is the cost of not repeating eight named arguments on restart. Re-running step 4 (`initializeDateFormatting`) on a restart is harmless.
- `lib/app/app.dart`: `_AppState` gains `late final AppLifecycleListener _lifecycle`, created in `initState` with `onShow: _backUpIfDue` and disposed in a new `dispose()`; `_runFirstFrameCallback` ends with `_backUpIfDue()`. App's `@Dependencies` gains `BackupController`, and so does every test that pumps App or carries App's dependency names: the five files that copy that list verbatim (`test/support/test_app.dart`, `test/widget/app/app_update_check_test.dart`, `test/integration/pending_approval_flow_test.dart`, `test/integration/recurring_transaction_test.dart`, `test/integration/memo_suggestions_flow_test.dart`) plus every other `@Dependencies` list under `test/` that names `userLocalePreference` (grep `userLocalePreference test/`; about 20 files on 2026-11-23), and whatever the lint asks of `bootstrap`, `bootstrapFor`, `buildBootstrappedTestApp` and `main`.

### Core helper

```dart
// date_helpers.dart, next to formatDisplayDate
static final Map<String, DateFormat> _displayDateTimeCache = {};

/// `Nov 23, 2026 2:05 PM` (en_US) / `2026年11月23日 下午2:05` (zh_TW) / `2026年11月23日 14:05` (zh_CN).
static String formatDisplayDateTime(DateTime date, String locale) =>
    _displayDateTimeCache
        .putIfAbsent(locale, () => DateFormat.yMMMd(locale).add_jm())
        .format(date);
```

Rows, the last-backup line and both confirm bodies call it, and AGENTS.md forbids building a `DateFormat` per row. It is a new shared helper, so commit 8 lists it in `PRD.md`, `docs/architecture/` and the *Performance rules* line of `AGENTS.md` that names the cached formatters. `formatDisplayDate` alone (date only) would cost nothing, but the confirms would not say which backup of a day they mean.

### Layer rules

Add `- "^package:google_sign_in/"` to `not_allow_import_reg_exps` of `widgets_forbid_data_internals`, `controllers_forbid_db_and_services`, `use_cases_forbid_ui` and `app_forbids_platform_plugins` in `import_analysis_options.yaml`. `service_providers.dart` stays excluded by the last rule's path regex. Repositories and services get no ban (PRD.md:1035). The federated `google_sign_in_*` packages need no pattern: `depend_on_referenced_packages` already stops imports of transitive packages.

Add `'package:google_sign_in/google_sign_in.dart'` to the three hand-written lists in `layer_boundaries_test.dart`: the `plugins` list of "feature files may not import platform or I/O plugins", the forbidden list of "use cases and the seed may import repositories, services, models and AppDatabase only", and the `plugins` list of "app files may not import platform plugins, except the service providers" (whose loop then also asserts that `service_providers.dart` may import it).

### Data flow

```
App first frame / onShow
  ▶ BackupController.backUpIfDue(after: startupRefresh)
      ▶ BackupRepository.isDue()                          (preferences only; not connected or off → stop)
      ▶ _run(backup) ▶ BackupRepository.backUp()          (as "Back up now" below)

BackupScreen
  ── watch ▶ backupAccountProvider ▶ BackupRepository.account()
               ▶ UserPreferencesRepository.getBackupAccountEmail  (null → not connected, no plugin call)
               ▶ _token(): GoogleAuthService.accessToken()         (silent; null → notAuthorized)
                           GoogleDriveService.accountEmail         (≠ stored email → notAuthorized)
               ▶ GoogleDriveService.list
  ── watch ▶ backupFrequencyProvider ▶ UserPreferencesRepository.watchBackupFrequency()
  ── tap Connect / Reconnect ▶ BackupController.connect()
               ▶ BackupRepository.connect()
                   ▶ GoogleAuthService.connect()           (picker + consent; null on cancel)
                   ▶ UserPreferencesRepository.setBackupAccountEmail
                   ▶ account() ▶ newest backup after last_backup_at, if restorable (D-25)
               ◀ offer ▶ showConfirmDialog ▶ Restore ▶ BackupController.restore(offer)
  ── tap Disconnect ▶ BackupController.disconnect()
               ▶ BackupRepository.disconnect()             (no network)
                   ▶ setBackupAccountEmail(null), setBackupFrequency(off)
                   ▶ GoogleAuthService.signOut()
  ── tap   ▶ BackupController.backUpNow()
               ▶ BackupRepository.backUp()
                   ▶ _token()                                (the account check)
                   ▶ GoogleDriveService.list                 (every page)
                   ▶ clone check: a same-id file newer than last_backup_at → new device_id
                   ▶ AppDatabase.exclusively(VACUUM INTO <cache>/ledgerly-backup.sqlite)
                   ▶ _attached(snapshot): quick_check, user_version == schemaVersion
                   ▶ GoogleDriveService.upload               (POST, then PUT to Location)
                   ▶ size check (mismatch → delete the new file, corrupt)
                   ▶ UserPreferencesRepository.setLastBackupAt
                   ▶ GoogleDriveService.delete × this device's previous files
               ▶ invalidate backupAccountProvider
  ── Restore ▶ BackupController.restore(b)
               ▶ BackupRepository.stageRestore(b)
                   ▶ GoogleDriveService.download ▶ <documents>/ledgerly.sqlite.restore.part
                   ▶ _attached(part): checks, newerSchema, device identity rows (D-15)
                   ▶ older → AppDatabase(part) once to migrate
                   ▶ DatabaseFileService.stageRestore      (rename → ledgerly.sqlite.restore)
               ▶ appRestart()
                   ▶ runApp(SizedBox.shrink) ▶ endOfFrame  (old container disposed)
                   ▶ db.close()
                   ▶ start(): applyStagedRestore ▶ open ▶ prefs ▶ seed skipped ▶ runApp(new scope)
```

---

## Dependencies

| Package          | Version  | Why                                                                                                                                                                                                                                                                                                                                                                                        |
|------------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `google_sign_in` | `^7.2.0` | First-party (flutter.dev). Latest release (2025-09-17). Under Flutter 3.50 it resolves `google_sign_in_android` 7.2.19 (Credential Manager) and `google_sign_in_ios` 6.4.0 (Swift Package Manager). The SDKs hold the grant and hand out fresh access tokens, so the app stores none and needs no `flutter_secure_storage`. 7.2.0 adds `clearAuthorizationToken`, which the 401 path uses. |

Nothing else: `dio` 5.11.1 handles Drive REST, `path_provider` 2.1.6 gives both directories, `uuid` makes the device id, and `drift`'s `exclusively` plus `customStatement` give the snapshot and the checks. `sqlite3` stays transitive.

Rejected: `googleapis` plus `googleapis_auth` (a large generated client for four REST calls); `extension_google_sign_in_as_googleapis_auth` (only useful with `googleapis`); `workmanager` (PRD § Automatic backup).

### Android

- No Gradle change. `google_sign_in_android` sets `minSdk = 24`; the app uses `flutter.minSdkVersion` (24) and `flutter.compileSdkVersion` (36) from Flutter 3.50. The pub.dev README's "SDK 21+" is out of date.
- Needs Google Play services (`play-services-auth` 21.6.0, `androidx.credentials` 1.6.0).
- No `google-services.json`: the Web client ID is passed as `serverClientId` in Dart, which Credential Manager requires.
- `AndroidManifest.xml` keeps no backup attributes, so Auto Backup keeps covering `app_flutter/` (D-7).

### iOS

- `ios/Runner/Info.plist` gains `GIDClientID` (the iOS client ID) and `CFBundleURLTypes` with `CFBundleURLSchemes` = the reversed iOS client ID. The URL scheme is required even when IDs are passed in Dart.
- The deployment target is already 15.0, which `google_sign_in_ios` 6.4.0 requires.
- `google_sign_in_ios` ships a `Package.swift` and pulls GoogleSignIn-iOS (9.0.0 to below 11.0.0), AppAuth, GTMAppAuth, GTMSessionFetcher, AppCheck and GoogleUtilities through Swift Package Manager, so `ios-nightly.yml`'s no-Podfile check stays green. GoogleSignIn-iOS 10.x's `Package.swift` is swift-tools-version 6.0, so the build needs **Xcode 16+**; raise the Xcode row in `docs/architecture/dependencies.md` from 15+ in commit 5. Add `google_sign_in_ios` to the list of iOS plugins with a `Package.swift` in `docs/architecture/dependencies.md` (line 102).

### Size check

In commit 5, run `flutter build apk --analyze-size --target-platform android-arm64` before and after, and record the delta in the commit body. `ios-nightly.yml` runs on the `pubspec.*` change and must pass.

---

## Localization

Add each key to `l10n/app_en.arb` after `csvExportNoneInRange`, with an `@key` description and, for its six placeholder keys, a `placeholders` block (type `String`, or `int` for `{days}`, with an example). Add the values to `app_zh_TW.arb` and `app_zh_CN.arb`, with an `@key` holding only `placeholders` for the six placeholder keys, as the CSV slice does. **Do not** touch `app_zh.arb`. Regenerate `lib/l10n/` with `flutter pub get`, and add every key to `_expectedEnKeys` in `test/unit/l10n/arb_audit_test.dart` under a `// Cloud backup (issue #157) (docs/superpowers/specs/2026-11-23-cloud-backup-design.md).` block after the period-picker block. Check the Google product names, and the name of the Google Account's third-party connections page in `backupDisconnectConfirmBody`, against Google's own en, zh_TW and zh_CN UI during review.

Placeholders: `{date}` is the output of `formatDisplayDateTime` (example `Nov 23, 2026 2:05 PM`, also in the ARB `placeholders` blocks); `{sizeMb}` is `_sizeMb` (example `1.2`); `{platform}` is `Android` or `iOS`; `{version}` is the app version (example `0.10.4`).

| Key                                                            | en                                                                                                                                                                                                              | zh_TW                                                                                                                                                     | zh_CN                                                                                                                                                       |
|----------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `settingsBackupTile`                                           | Google Drive backup                                                                                                                                                                                             | Google 雲端硬碟備份                                                                                                                                       | Google 云端硬盘备份                                                                                                                                         |
| `backupTitle`                                                  | Google Drive backup                                                                                                                                                                                             | Google 雲端硬碟備份                                                                                                                                       | Google 云端硬盘备份                                                                                                                                         |
| `backupIntro`                                                  | Back up all your Ledgerly data to your own Google Drive, then restore it on this or another device.                                                                                                             | 將所有 Ledgerly 資料備份到你自己的 Google 雲端硬碟，之後可在此裝置或其他裝置上還原。                                                                      | 将所有 Ledgerly 数据备份到你自己的 Google 云端硬盘，之后可在此设备或其他设备上恢复。                                                                        |
| `backupScopeNote`                                              | Ledgerly can only open its own backup files. It cannot see your other Drive files.                                                                                                                              | Ledgerly 只能開啟自己的備份檔案，看不到你在雲端硬碟中的其他檔案。                                                                                         | Ledgerly 只能打开自己的备份文件，看不到你在云端硬盘中的其他文件。                                                                                           |
| `backupPrivacyNote`                                            | The backup is not encrypted. It is stored in your Google account, and anyone who can sign in to that account can restore it.                                                                                    | 備份未加密，會儲存在你的 Google 帳戶中，任何能登入該帳戶的人都能還原它。                                                                                  | 备份未加密，会保存在你的 Google 账号中，任何能登录该账号的人都能恢复它。                                                                                    |
| `backupSectionAccount`                                         | Google account                                                                                                                                                                                                  | Google 帳戶                                                                                                                                               | Google 账号                                                                                                                                                 |
| `backupConnect`                                                | Connect Google account                                                                                                                                                                                          | 連結 Google 帳戶                                                                                                                                          | 关联 Google 账号                                                                                                                                            |
| `backupReconnectNeeded`                                        | Ledgerly can no longer reach your Google Drive. Reconnect to keep backing up.                                                                                                                                   | Ledgerly 已無法存取你的 Google 雲端硬碟，請重新連結以繼續備份。                                                                                           | Ledgerly 已无法访问你的 Google 云端硬盘，请重新关联以继续备份。                                                                                             |
| `backupReconnect`                                              | Reconnect                                                                                                                                                                                                       | 重新連結                                                                                                                                                  | 重新关联                                                                                                                                                    |
| `backupDisconnect`                                             | Disconnect                                                                                                                                                                                                      | 中斷連結                                                                                                                                                  | 断开关联                                                                                                                                                    |
| `backupDisconnectConfirmTitle`                                 | Disconnect Google account?                                                                                                                                                                                      | 要中斷連結 Google 帳戶嗎？                                                                                                                                | 要断开关联 Google 账号吗？                                                                                                                                  |
| `backupDisconnectConfirmBody`                                  | Backups stop on this device only. Other devices and the backups in your Google Drive are not affected. To remove Ledgerly's access on every device, remove it in your Google Account's third-party connections. | 只有此裝置會停止備份，其他裝置和 Google 雲端硬碟中的備份都不受影響。若要取消 Ledgerly 在所有裝置上的存取權，請在 Google 帳戶的第三方連結中移除 Ledgerly。 | 只有此设备会停止备份，其他设备和 Google 云端硬盘中的备份都不受影响。若要取消 Ledgerly 在所有设备上的访问权限，请在 Google 账号的第三方关联中移除 Ledgerly。 |
| `backupSectionAutomatic`                                       | Automatic backup                                                                                                                                                                                                | 自動備份                                                                                                                                                  | 自动备份                                                                                                                                                    |
| `backupFrequencyOff`                                           | Off                                                                                                                                                                                                             | 關閉                                                                                                                                                      | 关闭                                                                                                                                                        |
| `backupFrequencyDaily`                                         | Daily                                                                                                                                                                                                           | 每日                                                                                                                                                      | 每日                                                                                                                                                        |
| `backupFrequencyWeekly`                                        | Weekly                                                                                                                                                                                                          | 每週                                                                                                                                                      | 每周                                                                                                                                                        |
| `backupAutomaticNote`                                          | Automatic backups run while Ledgerly is open.                                                                                                                                                                   | 自動備份只會在 Ledgerly 開啟時執行。                                                                                                                      | 自动备份只会在 Ledgerly 打开时运行。                                                                                                                        |
| `backupNow`                                                    | Back up now                                                                                                                                                                                                     | 立即備份                                                                                                                                                  | 立即备份                                                                                                                                                    |
| `backupBackingUp`                                              | Backing up…                                                                                                                                                                                                     | 正在備份…                                                                                                                                                 | 正在备份…                                                                                                                                                   |
| `backupLastBackup` (`{date}`, `{sizeMb}`)                      | Last backup: {date} · {sizeMb} MB                                                                                                                                                                               | 上次備份：{date} · {sizeMb} MB                                                                                                                            | 上次备份：{date} · {sizeMb} MB                                                                                                                              |
| `backupNoBackupYet`                                            | This device has no backup yet.                                                                                                                                                                                  | 此裝置尚未備份。                                                                                                                                          | 此设备尚未备份。                                                                                                                                            |
| `backupTileOverdue` (int `{days}`; shown only when `{days}` >= 2, so a plain int placeholder is enough) | Last backup {days} days ago | 上次備份：{days} 天前 | 上次备份：{days} 天前 |
| `backupSectionList`                                            | Backups in Google Drive                                                                                                                                                                                         | Google 雲端硬碟中的備份                                                                                                                                   | Google 云端硬盘中的备份                                                                                                                                     |
| `backupListEmpty`                                              | There are no backups in this Google account yet.                                                                                                                                                                | 此 Google 帳戶中還沒有備份。                                                                                                                              | 此 Google 账号中还没有备份。                                                                                                                                |
| `backupLoadFailed`                                             | Couldn't reach Google Drive.                                                                                                                                                                                    | 無法連線到 Google 雲端硬碟。                                                                                                                              | 无法连接到 Google 云端硬盘。                                                                                                                                |
| `backupRetry`                                                  | Retry                                                                                                                                                                                                           | 重試                                                                                                                                                      | 重试                                                                                                                                                        |
| `backupThisDevice`                                             | This device                                                                                                                                                                                                     | 此裝置                                                                                                                                                    | 此设备                                                                                                                                                      |
| `backupEntryDetails` (`{platform}`, `{version}`, `{sizeMb}`)   | {platform} · Ledgerly {version} · {sizeMb} MB                                                                                                                                                                   | {platform} · Ledgerly {version} · {sizeMb} MB                                                                                                             | {platform} · Ledgerly {version} · {sizeMb} MB                                                                                                               |
| `backupEntryNeedsUpdate`                                       | Update Ledgerly to restore this backup                                                                                                                                                                          | 更新 Ledgerly 後才能還原此備份                                                                                                                            | 更新 Ledgerly 后才能恢复此备份                                                                                                                              |
| `backupRestore`                                                | Restore                                                                                                                                                                                                         | 還原                                                                                                                                                      | 恢复                                                                                                                                                        |
| `backupRestoreConfirmTitle`                                    | Restore this backup?                                                                                                                                                                                            | 要還原此備份嗎？                                                                                                                                          | 要恢复此备份吗？                                                                                                                                            |
| `backupRestoreConfirmBody` (`{date}`)                          | All data on this device will be replaced by the backup from {date}. This cannot be undone. Ledgerly restarts when it finishes.                                                                                  | 此裝置上的所有資料都會被 {date} 的備份取代，此操作無法復原。完成後 Ledgerly 會重新啟動。                                                                  | 此设备上的所有数据都将被 {date} 的备份替换，此操作无法撤销。完成后 Ledgerly 会重新启动。                                                                    |
| `backupRestoreOfferTitle`                                      | Restore from Google Drive?                                                                                                                                                                                      | 要從 Google 雲端硬碟還原嗎？                                                                                                                              | 要从 Google 云端硬盘恢复吗？                                                                                                                                |
| `backupRestoreOfferBody` (`{date}`, `{platform}`, `{version}`) | This Google account has a backup from {date} ({platform} · Ledgerly {version}). Restore it? All data on this device will be replaced, and Ledgerly restarts when it finishes.                                   | 此 Google 帳戶中有一份 {date} 的備份（{platform} · Ledgerly {version}），要還原嗎？此裝置上的所有資料都會被取代，完成後 Ledgerly 會重新啟動。             | 此 Google 账号中有一份 {date} 的备份（{platform} · Ledgerly {version}），要恢复吗？此设备上的所有数据都将被替换，完成后 Ledgerly 会重新启动。               |
| `backupRestoring`                                              | Restoring…                                                                                                                                                                                                      | 正在還原…                                                                                                                                                 | 正在恢复…                                                                                                                                                   |
| `backupDeleteConfirmTitle`                                     | Delete this backup?                                                                                                                                                                                             | 要刪除此備份嗎？                                                                                                                                          | 要删除此备份吗？                                                                                                                                            |
| `backupDeleteConfirmBody` (`{date}`)                           | The backup from {date} will be deleted from your Google Drive. This cannot be undone.                                                                                                                           | {date} 的備份將從你的 Google 雲端硬碟中刪除，此操作無法復原。                                                                                             | {date} 的备份将从你的 Google 云端硬盘中删除，此操作无法撤销。                                                                                               |
| `backupFailedNoNetwork`                                        | No internet connection. Try again when you're online.                                                                                                                                                           | 沒有網路連線，請連線後再試一次。                                                                                                                          | 没有网络连接，请联网后重试。                                                                                                                                |
| `backupFailedStorageFull`                                      | Your Google storage is full. Free up space, then try again.                                                                                                                                                     | 你的 Google 儲存空間已滿，請釋出空間後再試一次。                                                                                                          | 你的 Google 存储空间已满，请释放空间后重试。                                                                                                                |
| `backupFailedNewerSchema`                                      | This backup was made by a newer version of Ledgerly. Update Ledgerly, then try again.                                                                                                                           | 此備份由較新版本的 Ledgerly 建立，請更新 Ledgerly 後再試一次。                                                                                            | 此备份由较新版本的 Ledgerly 创建，请更新 Ledgerly 后重试。                                                                                                  |
| `backupFailedCorrupt`                                          | The backup file is damaged. Nothing was changed.                                                                                                                                                                | 備份檔案已損毀，未做任何變更。                                                                                                                            | 备份文件已损坏，未做任何更改。                                                                                                                              |

41 new keys. Reused: `commonDelete` (the Delete action and its confirm), `commonCancel` (inside `showConfirmDialog`, including the restore offer's Cancel), `errorSnackbarGeneric` (`unknown`). `notAuthorized` has no key of its own; it shows `backupReconnectNeeded`. Also update the `@settingsSectionDataManagement` description (`app_en.arb:1177`) to mention Google Drive backup.

---

## Privacy & Security

- **Opt-in.** `backup_frequency` defaults to `off`, `backup_account_email` to null, and nothing calls Google until the user taps Connect. Startup on a device that is not connected, or has backups off, never touches `google_sign_in`.
- **Smallest scope.** `drive.appdata` is the only Drive scope, and Google lists it as non-sensitive. Sign-in also returns the account's basic profile; the app uses only the email: it stores it, shows it, and checks each silent token against it (P2 discloses this). The app cannot see the user's other Drive files, and its files are invisible in the Drive UI (`backupScopeNote`).
- **Unencrypted, and said so.** The file is a plain SQLite snapshot protected by the Google account and Drive's server-side encryption. `backupPrivacyNote` says so, as `csvExportPrivacyNote` does for CSV.
- **No stored token.** The SDKs hold the grant. Each run asks for an access token, keeps it in memory, and sends it only as an `Authorization` header on Drive requests. It is never sent as a URL query parameter, and never through an interceptor on the shared `Dio`.
- **The account email is stored.** `backup_account_email` lives in `user_preferences`, so it is also in every Drive backup this device makes and in Android Auto Backup and iOS device backups (P2 says so). Disconnect clears it on the device; earlier backups keep it.
- **Disconnect is local.** It clears the stored email, sets `backup_frequency` to `off`, and calls `GoogleSignIn.signOut()`, which revokes nothing (D-16, S3-c). The grant stays, so the confirm and P2 point to the Google Account's third-party connections page for removing Ledgerly's access everywhere.
- **No financial data in Drive metadata.** `appProperties` hold only the five keys in [Drive file format](#drive-file-format). `device_id` is a random UUID, not a hardware id.
- **Logs.** `${e.runtimeType}` only. Never a `DioException`'s message or request (they carry URLs and file ids), file names, paths, the email, tokens or anything from the ledger. No `debugPrint` traces.
- **Temp copies.** The snapshot lives in the cache directory (which Android Auto Backup excludes) and is deleted in `finally`. The restore download lives in the documents directory and is deleted on failure or renamed into place.
- **A restored file is trusted data.** Opening a SQLite file runs its views and triggers; only this Cloud project's clients can write the `appDataFolder`, and `quick_check` does not validate the schema. Accepted.
- **OS backups stay on** (D-7). They already hold the unencrypted database. A `.restore.part` present at backup time could also be captured; the window is the length of one download.
- **Unchanged:** exchange-rate requests carry only currency pairs; the update check carries no user data. `PRD.md` § Security & Privacy already has the cloud-backup line; it gains the stored email (Deviation 7). One other change: the in-process restart runs a second release check, so PRD.md:1432 "once per launch" becomes "once per launch, and once more after an in-process restore restart", and `docs/architecture/bootstrap.md:14` "one GitHub `releases/latest` GET per launch" gets the same qualifier (commit 4).

---

## Copy that goes stale

| File                                                                         | Where                                                                                          | Change                                                                                                                                                                                                                                                                                                                                                                                              | Commit |
|------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------|
| `PRD.md`                                                                     | lines 718-721, 949, 962, 964, 981-982, 994-1000, 1011, 1012, 1013, 1020, 1026, 1031, 1034, 1042, 1051, 1061, 1068, 1435 | The [Deviations](#deviations-from-prd).                                                                                                                                                                                                                                                                                                                                                             | 1      |
| `PRD.md`, `docs/architecture/layers.md`, `docs/architecture/dependencies.md` | PRD.md:83-96 (Layer Boundaries table and prose), layers.md:7 and 47, dependencies.md:18 and 22 | Add `google_sign_in` to the plugin bans.                                                                                                                                                                                                                                                                                                                                                            | 5      |
| `PRD.md`                                                                     | § Dependencies (1534-1550)                                                                     | Delete the `google_sign_in` row from § Deferred, and add `### Phase 3 Additions (shipped)` after § Phase 2 Additions, holding `\| google_sign_in \| ^7.2.0 \| Google account grant for the drive.appdata scope (cloud backup) \|`.                                                                                                                                                                  | 5      |
| `docs/architecture/dependencies.md`                                          | line 102                                                                                       | Add `google_sign_in_ios` to the iOS plugins that ship a `Package.swift`.                                                                                                                                                                                                                                                                                                                            | 5      |
| `docs/architecture/bootstrap.md`                                             | after the first-frame paragraph (line 14)                                                      | The staged-restore swap before the database opens; the restart path and why the interim frame is needed.                                                                                                                                                                                                                                                                                            | 3, 4   |
| `PRD.md`, `docs/architecture/bootstrap.md`                                   | PRD.md:1432; bootstrap.md:14                                                                   | "once per launch" / "one GitHub `releases/latest` GET per launch" gain "and once more after an in-process restore restart" ([Privacy & Security](#privacy--security)).                                                                                                                                                                                                                              | 4      |
| `PRD.md`, `docs/architecture/`, `AGENTS.md`                                  | PRD folder tree and shared helpers; *Performance rules* line on cached formatters              | `DateHelpers.formatDisplayDateTime`.                                                                                                                                                                                                                                                                                                                                                                | 8      |
| `docs/architecture/layers.md`                                                | *Where things live*; the sub-slice list (line 32)                                              | `DatabaseFileService`, `GoogleAuthService`, `GoogleDriveService`, `BackupRepository`, `appRestartProvider`; `ui/features/settings/backup/`.                                                                                                                                                                                                                                                         | 7, 10  |
| `PRD.md`                                                                     | routing table (lines 1083-1106)                                                                | Add `/settings/backup` after `/settings/import`.                                                                                                                                                                                                                                                                                                                                                    | 10     |
| `PRD.md`                                                                     | Screens inventory, "Settings Screen" item (working tree line 1154)                             | Add "Google Drive backup (Data Management)".                                                                                                                                                                                                                                                                                                                                                         | 12     |
| `docs/architecture/ui-and-layout.md`, `docs/architecture/bootstrap.md`       | ui-and-layout.md:22 (`_AdaptiveFormRoute` list); bootstrap.md:28 (route table)                 | Add `/settings/backup`.                                                                                                                                                                                                                                                                                                                                                                             | 10     |
| `lib/ui/features/settings/views/settings_screen.dart`, `l10n/app_en.arb`     | header comment (lines 8-9); `@settingsSectionDataManagement` (line 1177)                       | Mention the backup tile.                                                                                                                                                                                                                                                                                                                                                                            | 10     |
| `docs/architecture/bootstrap.md`                                             | first-frame paragraph                                                                          | The automatic backup check after the update check and on `onShow`.                                                                                                                                                                                                                                                                                                                                  | 11     |
| `README.md`                                                                  | lines 4, 40-41, 50, 55                                                                         | Keep the local-first claim, but replace "all data lives on the device" (line 4) and the nearby on-device phrasing (40-41, 50, 55) with "data lives on the device; optional backup to your own Google Drive".                                                                                                                                                                                      | 12     |
| `README.md`                                                                  | Settings feature list (207-224); "What Ledgerly does not do today" (244-252)                   | Add a backup bullet. Replace "sign-in or cloud backup" with "cloud sync (backup to your own Google Drive is a one-way snapshot, not sync)".                                                                                                                                                                                                                                                         | 12     |
| `site/src/pages/index.astro`                                                 | line 19                                                                                        | "Track your spending privately. No Ledgerly account, no subscriptions — your data stays on your phone unless you back it up to your own Google Drive."                                                                                                                                                                                                                                              | 12     |
| `site/src/pages/index.astro`                                                 | lines 31-32                                                                                    | "Your financial data stays on your device. No Ledgerly account, no cloud sync, no tracking. Optional backups go to your own Google Drive, never to our servers."                                                                                                                                                                                                                                    | 12     |
| `site/src/content/docs/ledgerly-guide/getting-started.md`                    | lines 10-11, 20, 25                                                                            | Same wording change as the README.                                                                                                                                                                                                                                                                                                                                                                  | 12     |
| `site/src/content/docs/ledgerly-guide/mvp-limitations.md`                    | line 12                                                                                        | As the README's "does not do" list.                                                                                                                                                                                                                                                                                                                                                                 | 12     |
| `site/src/content/docs/ledgerly-guide/main-screens.md`                       | Settings list (105-120)                                                                        | Add Google Drive backup.                                                                                                                                                                                                                                                                                                                                                                            | 12     |
| `site/src/content/docs/privacy.md`, `site/astro.config.mjs`                  | new page; sidebar (11-21)                                                                      | P2.                                                                                                                                                                                                                                                                                                                                                                                                 | 12     |
| `docs/architecture/testing.md`                                               | *Where slice coverage lives*, after CSV export (line 42)                                       | A "Cloud backup" line with the test files below.                                                                                                                                                                                                                                                                                                                                                    | 12     |
| `PRD.md`                                                                     | 459, 1520, 1538                                                                                | Add "Google Drive backup" to the Dio (459, 1538) and `path_provider` (1520) purposes.                                                                                                                                                                                                                                                                                                               | 6, 7   |
| `PRD.md`                                                                     | 947 heading, 58, 445, 718, 949, 1435                                                           | Rename the heading to "## Cloud Backup (Phase 3 — shipped YYYY-MM-DD)" with the merge date, as line 590's heading does, and update its three anchor links (58, 718, 1435); make line 445 a numbered bootstrap step without "(planned)"; drop "planned" at 718; mark line 58 `[Shipped YYYY-MM-DD]` with the same date, as line 57 does; rewrite the status block at 949 to say the feature shipped. | 12     |
| `PRD.md` folder tree                                                         | 132-142 (and the 135 comment), 184-190, 191-202, 207-221, 390-404                              | Add `app/providers/app_restart_provider.dart`; `data/services/{database_file,google_auth,google_drive}_service.dart`; `data/repositories/backup_repository.dart`; `domain/models/drive_backup.dart`; `ui/features/settings/backup/{view_models,views}/`. Line 135's comment adds "Google auth".                                                                                                     | 12     |

These stay true and need no change: `csvImportPrivacyNote` (it is about the CSV file), PRD's "local-first" and "no sign-in requirement" lines and its "cloud sync" non-goal (backup is opt-in and is not sync), and `pubspec.yaml`'s description.

**When:** README and site claims ship in the feature PR, because they become false once a user opts in. After the PR merges, `github-pages.yml` deploys the privacy page; then set the consent screen to In production; then tag the release (`android-release.yml`). Run `corepack enable`, `yarn --cwd site install --immutable`, `yarn --cwd site test`, `yarn --cwd site check` and `yarn --cwd site build` in commit 12.

---

## Testing

TDD per AGENTS.md: write each test first and watch it fail. Drift work in widget tests runs inside `tester.runAsync`. Pump with `pump()`, never `pumpAndSettle`, while a spinner shows.

**Unit — repositories**

- `test/unit/repositories/user_preferences_repository_test.dart` (extend), a "cloud backup" group:
  - defaults: `off`, null, null, null;
  - frequency round trip and `watchBackupFrequency` emissions; `watchLastBackupAt` emits after `setLastBackupAt`;
  - a stored `'"hourly"'` throws `PreferenceDecodeException` (the corrupt-row pattern of this file);
  - `last_backup_at` written in local time reads back as the same instant, in UTC;
  - `device_id` round trip;
  - `backup_account_email` round trip, and `setBackupAccountEmail(null)` after a value reads back null.
- `test/unit/repositories/backup_repository_test.dart`. Use `newFileTestAppDatabase(File)` from `test/unit/repositories/_harness/test_app_database.dart` (added in commit 4; the harness forbids local DB helpers), mocktail mocks of `GoogleAuthService` and `GoogleDriveService`, `DatabaseFileService` on temp directories, `clock: () => DateTime.utc(2026, 11, 23, 14)` and `appVersion: () async => '0.10.4'`. Unless a case says otherwise, the device is connected: `backup_account_email` is stored and `accountEmail` returns it.
  - **Round trip:** seed, add transactions, `backUp()` (the upload mock copies the file it gets), add and delete rows, `stageRestore` (the download mock writes the copy), close the live database, `applyStagedRestore`, open a new `AppDatabase` on the file. Every table equals the backup, except that, read through the preferences API, `backup_account_email` and `backup_frequency` equal the device's pre-restore values, `device_id` equals the device's pre-restore value when the backup's `appProperties['device_id']` matches it, and `last_backup_at` equals the clock's restore time; theme, locale, splash settings and default currency equal the backup's. The backup's own `backup_account_email` row is set to a different email before the restore, so the test sees which one wins. Wrap `stageRestore` in `verifyNever(upload)`/`verifyNever(delete)` to cover AC5's "nothing in Drive changes".
  - **Restoring another device's backup:** the download mock writes a backup whose `appProperties['device_id']` is another device's; `stageRestore` gives the device a new `device_id` (locally and in the staged file), and a later `backUp()` deletes nothing (`verifyNever(delete)`), so the other device's file survives (D-15).
  - A device with no `backup_frequency` row that restores a Daily backup reads `daily`.
  - After a restore, `isDue()` with Daily is false at the restore time and true 20 h later.
  - `appProperties` hold exactly the five keys, in the formats above.
  - `verifyInOrder([accountEmail, list, upload, delete(myOldFile)])`; `last_backup_at` is written before the prune; `verifyNever(delete(otherDevicesFile))`; a file without `device_id` is never deleted.
  - **Clone check:** local `last_backup_at` = T0, and Drive has a file with the same `device_id` and `created_at` T1 after T0 → the upload is tagged with a new UUID, the stored `device_id` is that UUID, `verifyNever(delete)`, and `account()` then lists the T1 file with `isThisDevice == false`. A same-id file whose `created_at` equals `last_backup_at` is pruned as usual. A stored `device_id` with a null `last_backup_at` and a same-id file in Drive → the upload is tagged with a new UUID and `verifyNever(delete)`.
  - `list` throws `DioException(connectionError)` → `BackupException(noNetwork)`; no snapshot file is created and `upload` is never called.
  - Upload throws `DioException(connectionError)` → `BackupException(noNetwork)`; no delete; `last_backup_at` unchanged; no snapshot file left.
  - 403 `storageQuotaExceeded` → `storageFull`; 401 → `clearToken` called, then `notAuthorized`; other 403, 429 and 500 rethrow.
  - Uploaded size differs → `corrupt`; `verify(delete(newId))`; `verifyNever(delete(myOldFile))`; `last_backup_at` unchanged.
  - No token → `notAuthorized`, no Drive call, no snapshot.
  - The account check: `accountEmail` returns another email → `notAuthorized` from `backUp()`, `stageRestore()` and `delete()`, with no `list`, `upload`, `download` or `delete` call and no snapshot; the stored email in other letter case passes.
  - A leftover `<cache>/ledgerly-backup.sqlite` does not stop the backup.
  - `stageRestore`: a file with `PRAGMA user_version = 9` → `newerSchema`, no `.restore`, local data unchanged; junk bytes → `corrupt` (it fails at `ATTACH`); an empty file and a SQLite file with `user_version` 0 → `corrupt`; a hot `.restore.part-journal` left from a different file does not change the staged rows.
  - An older backup: build a v7 file from `_harness/generated/schema_v7.dart` with `VACUUM INTO`; `stageRestore` leaves a `.restore` with `user_version` 8 that passes `quick_check`.
  - A device without `device_id` gets a UUID (`uuidV4`) both locally and in the staged file.
  - `account()`: no stored email → null with no call on the auth mock; a null token → `notAuthorized` with no Drive call; another `accountEmail` → `notAuthorized` with no `list` call; returns the stored email; skips files with missing or bad keys; newest first; `isThisDevice`; `restorable` false for `schema_version` 9.
  - `isDue()`: no stored email → false with no call on the auth mock, even with Daily and no `last_backup_at`; `off` → false with no call on the auth mock; Daily: never backed up → true, 19 h → false, 20 h → true, `last_backup_at` 30 days in the future → true; Weekly: 6 d 19 h → false, 6 d 20 h → true.
  - `connect()` (D-25): the auth mock returns null (picker cancelled) → null, no email written, no Drive call; on success the email is written before the listing; `last_backup_at` null and no transactions → the newest backup when it is restorable; `last_backup_at` null and one transaction → null; the newest backup created after `last_backup_at` but not restorable → null, even when an older one would be; every backup created at or before `last_backup_at` → null; a listing that throws `DioException(connectionError)` → `BackupException(noNetwork)` with the email still stored.
  - `disconnect()`: writes a null email and `off`, then calls `signOut()`; no Drive call and no `accessToken()`. A `signOut()` that throws `PlatformException` rethrows, with the email already null and the frequency `off`.
  - `delete()` passes the file id.

**Unit — services**

- `test/unit/services/database_file_service_test.dart` (temp directories through the injected getters). Commit 3: no staged file → no-op; staged file plus a leftover `-journal` → journal deleted, staged bytes at `ledgerly.sqlite`, `.restore` gone; staged file without a journal; `databasePath` is `<documents>/ledgerly.sqlite`. Commit 7: `stageRestore` renames `.part`; `snapshotFile` deletes a leftover; `restoreDownloadFile` deletes a leftover `.part` and `.part-journal`.
- `test/unit/services/google_drive_service_test.dart` (`MockDio extends Mock implements Dio`): `list` query parameters and parsing with a string `size`, skipping malformed entries; two `list` pages are concatenated, and the second request carries the first page's `pageToken`; `upload` sends the resumable `POST` (URL, `uploadType`, JSON metadata, `X-Upload-*` headers), then the `PUT` to the `Location` with `Content-Length`, and returns id and size; `download` uses `alt=media` and `deleteOnError`; `delete` treats 404 as success and throws on 500; `accountEmail` parsing; a Bearer header on every call and no `access_token` query parameter.
- `test/unit/services/google_auth_service_test.dart` (mocktail `GoogleSignIn`, `GoogleSignInAuthorizationClient`, `GoogleSignInAccount`): two services on one `GoogleSignIn` call `initialize` once; `connect` returns the email of the account `authenticate()` returned, after `authorizeScopes` on that account's client; `connect` with `canceled` returns null and with `clientConfigurationError` rethrows; `authorizeScopes` throwing `unknownError` during `connect` rethrows; `accessToken` is null when `authorizationForScopes` returns null; `signOut` calls `GoogleSignIn.signOut()` and never `disconnect()`.

**Unit — core**

- `test/unit/utils/date_helpers_test.dart` (extend): `formatDisplayDateTime` equals `DateFormat.yMMMd(locale).add_jm()` for `en_US` and `zh_TW`.

**Unit — controller**

- `test/unit/controllers/backup_controller_test.dart` (mocktail `BackupRepository` and `UserPreferencesRepository`, `@Dependencies([BackupController])` on `main`; `build()` is synchronous, so use `container.listen` and read the provider directly):
  - each command goes `idle → working(job) → idle` and invalidates `backupAccountProvider`;
  - each `BackupException(f)` → `failed(f)`; any other exception → `failed(unknown)`;
  - a command during `working` is ignored;
  - `connect` returns the repository's offer; it returns null when the repository returns null, when it throws (the state is `failed`), and when the command is ignored;
  - `backUpIfDue` does nothing and starts no timer when `isDue` is false or throws (`fakeAsync`: no pending timer); when a backup is due, it waits for `after` (a `Completer`), gives up waiting after 30 s (`fakeAsync`), and runs one backup; a first-frame call and an `onShow` call that overlap run one backup;
  - `restore` stages, then calls the overridden `appRestartProvider`; a staging failure → `failed`, and the restart is not called;
  - a `restore` whose fake `appRestartProvider` disposes the container completes without throwing (no state write, no invalidate);
  - `setFrequency` writes the preference; a throw → `failed(unknown)`; a throw during `working(backup)` leaves the state at `working(backup)`; a call during `working(disconnect)` writes nothing (radio-tap race).

**Unit — app**

- `test/unit/app/bootstrap_restart_test.dart` (S2's automated part). Drive `bootstrapFor` with a temp-directory file database: `openDatabase` runs `DatabaseFileService(documentsDirectory: () async => tmp).applyStagedRestore()` and returns `newFileTestAppDatabase(File('${tmp.path}/ledgerly.sqlite'))`; `runAppFn` captures each widget.
  - A file staged before the first `bootstrapFor` is opened, and a leftover journal is deleted.
  - Stage a file with different rows and a different theme, build a container from the captured overrides, call `appRestartProvider`, pump the captured interim widget, and assert: a `SizedBox` was launched before the new `ProviderScope`; the old `AppDatabase` rejects a query; the new scope's `initialThemeModeProvider` and its repositories read the staged values.
  - This must be a `testWidgets` file, not a plain `test()`: `restart()` awaits `endOfFrame` and then runs real file and Drift I/O, so start the restart unawaited and alternate `tester.pump()` with `tester.runAsync(...)` until the launched scope appears (the `pumpUntilFound` pattern of `test/support/test_app.dart`). It cannot prove the interim frame disposed the old scope — the captured scopes are never mounted — so S2's device check still covers that half.
- `test/unit/app/bootstrap_order_test.dart` (extend): the root `ProviderScope` overrides `appRestartProvider`.
- `test/unit/app/router_test.dart` (extend): `/settings/backup` uses a root modal route; a `Dialog` at 1000×800 and none at 390×844. The test database stores no email, so the real `backupAccountProvider` makes no plugin call.
- `test/unit/providers/provider_graph_test.dart`: add `backupRepositoryProvider` to the providers that resolve without throwing (the services' constructors have no side effects).

**Unit — architecture and l10n**

- `test/unit/architecture/layer_boundaries_test.dart`: the three lists above. No new baseline entries.
- `test/unit/l10n/arb_audit_test.dart`: the new block.
- `test/unit/l10n/cloud_backup_l10n_test.dart` (new, like the other per-slice l10n tests): every key renders in `en`, `zh_TW` and `zh_CN`; the six placeholder keys interpolate; `backupDisconnectConfirmBody` uses Google's current page name.

**Widget**

- `test/widget/features/settings/backup_screen_test.dart`. A `_FakeBackupController extends BackupController` returns a fixed state and records command calls; `backupAccountProvider` and `backupFrequencyProvider` are overridden. `@Dependencies([BackupController, backupAccount, backupFrequency])` on `main` and on the pump helper. Cases:
  - account loading; a load error other than `notAuthorized` shows `backupLoadFailed`, and Retry re-reads the provider; the state `failed(noNetwork)` while `backupAccountProvider` fails with `BackupException(noNetwork)` also shows `backupFailedNoNetwork`; Disconnect → confirm calls `disconnect`;
  - not connected: intro, scope and privacy notes, Connect calls `connect`, no list;
  - reconnect: `backupAccountProvider` failing with `BackupException(notAuthorized)` shows `backupReconnectNeeded` and Reconnect, and Reconnect calls `connect`; Disconnect → confirm calls `disconnect`;
  - restore offer: a fake `connect()` that returns a backup shows the offer dialog with that backup's date, platform and version; Restore calls `restore(offer)`; Cancel calls nothing; a `connect()` that returns null shows no dialog. The same from the connected body's Reconnect button;
  - restore offer while the body changes: `backupAccountProvider` is overridden with a function that reads a test variable, and the fake `connect()` sets it to a connected `BackupAccount` and invalidates the provider before it returns the offer, as `_run` does. Pump until `_ConnectedBody` shows behind the dialog, tap Restore, and expect `restore(offer)`. Run it from the not-connected body (null → data) and from the reconnect body (a `notAuthorized` error → data);
  - connected idle: the email, the selected radio, tapping Daily calls `setFrequency(daily)`; the radio is disabled while each working job runs (one case per job), and `working(connect / disconnect / delete)` disables Connect/Reconnect, Disconnect, Back up now and the row menus;
  - Back up now calls `backUpNow`; `working(backup)` disables it, shows "Backing up…" and allows pop;
  - connected and `failed(notAuthorized)`: shows `backupReconnectNeeded` and Reconnect, and tapping Reconnect calls `connect`;
  - `working(restore)` shows "Restoring…" and blocks pop (the CI04 pattern in `csv_import_screen_test.dart`);
  - each `BackupFailure` maps to its text, in a loop;
  - an empty list; a this-device row and another device's row with their details; the last-backup line from this device's row, and `backupNoBackupYet` without one;
  - a non-restorable row has no Restore item and shows the needs-update line;
  - Restore confirm calls `restore(entry)`; Cancel calls nothing; Delete confirm; Disconnect confirm, whose body says this device only;
  - 2× text scale full-screen at 390×844, and at 1000×800 inside a centred `ConstrainedBox(maxWidth: 560)` (the box `_AdaptiveFormRoute` gives it; that class is private to `router.dart`): scroll to the last row, assert rendered sizes, and expect `takeException()` to be null;
  - one `zh_TW` render.
- `test/widget/features/settings/settings_screen_test.dart` (extend): a `/settings/backup` stub in `_StubRouter`, and SS05f mirroring SS05c: the tile sits in the Data Management section and pushes the route. SS05g overrides `backupFrequencyProvider` and `backupLastBackupAtProvider`: Daily with a last backup 3 days ago shows "Last backup 3 days ago"; Daily with none shows `backupNoBackupYet`; Daily with one 30 hours ago, and Off with one 30 days ago, show no subtitle; a loading stream shows none; Daily at 47 h 59 m shows none and at 48 h shows it; Weekly at 13 d 23 h shows none and at 14 d shows it; a `last_backup_at` in the future shows none. Update the header comment. The `_MockUserPreferencesRepository` gains stubs (or the cases override `backupFrequencyProvider`/`backupLastBackupAtProvider`) because the tile now subscribes to both streams, and the file's two `@Dependencies` lists gain `backupFrequency` and `backupLastBackupAt` (same as `routerProvider`).
- `test/widget/app/backup_trigger_test.dart`, modelled on `app_update_check_test.dart`: `buildTestApp` with `backupRepositoryProvider` overridden by a mock.
  - One backup after the first frame and the startup FX refresh when due; none when not due.
  - With no `backup_account_email`, the real `BackupRepository` over mocked auth/Drive starts no backup and makes no `accessToken` call (`verifyNever`), which covers AC1's "startup makes no google_sign_in call" through the real App → controller → repository path.
  - `handleAppLifecycleStateChanged` stepped through `inactive`, `hidden`, `paused`, `hidden`, `inactive`, `resumed` checks again.
  - `inactive` → `resumed` alone (the notification shade) checks nothing.
  - An `onShow` while a backup runs starts no second one, and pumping after the backup finishes starts none.
  - The `last_backup_at` write starts nothing: stub `backUp()` to write `last_backup_at` through the real `userPreferencesRepositoryProvider` inside `tester.runAsync`, pump, then `verify(() => repo.backUp()).called(1)`.

**Integration:** none beyond the above. `buildBootstrappedTestApp` cannot follow a second launch, and `bootstrap_restart_test.dart` drives the real `bootstrapFor` while the repository round trip covers the data.

**Device checks** (manual, before release): S1 and S3; a release-signed APK against the In-production consent screen (connect, back up, list, restore, delete, disconnect); a second device that keeps backing up after the first disconnects (criterion 13); the restore offer on a fresh install and after Connect to another account (criterion 14; S3 runs before the offer exists); `ios-nightly.yml` passing without a Podfile.

---

## Commit plan

Each commit passes `dart format --set-exit-if-changed .`, `dart analyze --fatal-infos` and `flutter test` on its own, and regenerates generated parts (`build_runner`, `flutter pub get` for l10n) in the commit that changes their sources. Run S2 after commit 4, before commit 5 starts, and S1 and S3 after commit 6, before commit 7 starts (Deviation 6).

| #  | Commit                                                        | Contents                                                                                                                                                                                                                                                                                                                                                                      |
|----|---------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1  | `docs: add the cloud backup design spec`                      | This file and the `PRD.md` edits under [Deviations from PRD](#deviations-from-prd).                                                                                                                                                                                                                                                                                           |
| 2  | `feat(data): add the cloud backup preferences`                | `drive_backup.dart`, the four keys in `user_preferences_repository.dart`, and tests.                                                                                                                                                                                                                                                                                          |
| 3  | `feat(app): apply a staged restore before the database opens` | `database_file_service.dart` (`databasePath`, `applyStagedRestore`), the `openDatabase` change in `bootstrap()`, `database_file_service_test.dart` (the commit-3 cases), `bootstrap.md`.                                                                                                                                                                                      |
| 4  | `feat(app): restart in-process to finish a restore`           | `app_restart_provider.dart` + `.g.dart`, the `start()` split and the override in `bootstrapFor`, `newFileTestAppDatabase(File)` in `test/unit/repositories/_harness/test_app_database.dart`, `bootstrap_restart_test.dart`, the `bootstrap_order_test.dart` case, `bootstrap.md`, and the "once more after a restore restart" qualifier in PRD.md:1432 and `bootstrap.md:14`. |
| 5  | `build(deps): add google_sign_in for Google Drive backup`     | `pubspec.yaml`, `pubspec.lock`, `Info.plist`, the import bans and `layer_boundaries_test.dart`, the Xcode 16 row in `dependencies.md`, and the PRD, `layers.md` and `dependencies.md` edits. APK size delta in the body.                                                                                                                                                                                             |
| 6  | `feat(data): add the Google auth and Drive services`          | `google_auth_service.dart` (with the P1 Web client ID), `google_drive_service.dart`, `googleAuthServiceProvider` + `service_providers.g.dart`, both service tests, and the Dio purposes in PRD.md:459 and 1538.                                                                                                                                                               |
| 7  | `feat(data): back up to and restore from Google Drive`        | `backup_repository.dart`, the rest of `DatabaseFileService`, `backupRepositoryProvider` + `repository_providers.g.dart`, the `snapshotFile`, `restoreDownloadFile` and `stageRestore` cases in `database_file_service_test.dart`, `backup_repository_test.dart`, `provider_graph_test.dart`, `layers.md`, and the `path_provider` purpose in PRD.md:1520.                     |
| 8  | `feat(core): add a cached date-time display format`           | `DateHelpers.formatDisplayDateTime`, its test, and the `PRD.md`, `docs/architecture/` and `AGENTS.md` mentions.                                                                                                                                                                                                                                                               |
| 9  | `feat(settings,l10n): add the backup controller and strings`  | `backup_state.dart`, `backup_controller.dart`, `backup_providers.dart` + generated parts, the ARB keys in 3 files (including `backupTileOverdue`) + regenerated `lib/l10n/`, `arb_audit_test.dart`, `cloud_backup_l10n_test.dart`, `backup_controller_test.dart`.                                                                                                                                                                            |
| 10 | `feat(settings,app): add the Google Drive backup screen`      | `backup_screen.dart`, the route + regenerated `router.g.dart`, the Settings tile with its overdue subtitle (D-26), the `SettingsScreen` `@Dependencies` change, `settings_screen_test.dart`'s two `@Dependencies` lists and mock stubs, the header comment, the ARB description, the widget tests, the router test, and the route and sub-slice docs.                                                                                                                                                                                |
| 11 | `feat(app): back up automatically while the app is open`      | `app.dart` (first frame and `onShow`), the `@Dependencies` changes in `lib/` and `test/`, `backup_trigger_test.dart`, `bootstrap.md`.                                                                                                                                                                                                                                         |
| 12 | `docs: describe Google Drive backup and add a privacy page`   | README, site pages, `privacy.md` and the sidebar, `testing.md`, and the PRD heading and anchors, status, roadmap, bootstrap note, preference-keys note, Settings-screen inventory and folder tree.                                                                                                                                                                                                       |

Commit 11 cannot split its `@Dependencies` edits from `app.dart`: `dart analyze --fatal-infos` fails on either half alone.

PR title (per AGENTS.md): `Problem: No cloud backup`.

---

## Risks / Known limitations

- **Decided trade-offs** (PRD.md:971): the backup is unencrypted; there is one generation, so a backup taken after an accidental delete replaces the good one; Android needs Google Play services; automatic backups wait until the app is open, so "Daily" means at least 20 hours since the last one and the app shown; switching Google accounts hides the old account's backup; uninstalling leaves the backup in Drive.
- **Cloned `device_id`.** `device_id` lives in `ledgerly.sqlite`, which Android Auto Backup and iOS device backup or migration copy, so a new phone or a reinstall can start with an older copy of another install's id. The clone check (Backup flow step 4) catches it whenever the other install has backed up since the copy was taken: Drive then holds a same-id file newer than this copy's `last_backup_at`, so this install's first backup takes a new id and prunes nothing, and the newer file lists as another device's. If both phones stay active, whichever backs up second diverges this way. A copy taken while `last_backup_at` was still null (an id stored by a first attempt that never finished) is caught the same way: with no `last_backup_at`, every same-id file counts as another install's. If the other install has not backed up since the copy, the only same-id file is one whose data the copy already holds, and pruning it loses nothing. Until that first backup, the other install's file shows as "This device". Restoring another install's own backup on a clone (the usual path when the restore offer (D-25) appears on an OS-migrated phone) keeps the id and prunes that same file, which loses nothing: the restored data holds it, and if the other install is still in use, its next backup finds the newer same-id file and takes a new id. Restoring a third device's backup gives the clone a new id (D-15), so the clone cannot prune that device's file. It does not catch:
  - clock skew between devices larger than the gap between the copy and the other install's backup;
  - a clone whose first backups go to another account: they move `last_backup_at` past the other install's newer file in the first account, so a later Reconnect to that account neither offers that file nor keeps it, and the next backup prunes it.

  Moving the id out of the database would also need an Auto Backup exclusion rule; not done.
- **A false clone.** If an upload reaches Drive but its response does not (a receive timeout, or the process killed between steps 8 and 10), Drive holds an own file newer than `last_backup_at`. The next backup takes a new id, and that file stays as another device's backup until the user deletes it; the previous own files tagged with the old id stay too, so the list can show more than one stale row. No data is lost. Until that next backup, Connect or Reconnect can offer the file (D-25); restoring it rolls back what was entered after it.
- **Switching accounts keeps `last_backup_at`.** It is not tied to an account, so after Disconnect and Connect to another account (or a Reconnect that picks another account), the first automatic backup to the new account waits out the rest of the period; the screen shows "This device has no backup yet" and Back up now works at once. Clearing `last_backup_at` on Connect would fix this but would skip the clone check exactly when a cloned phone connects. For the same reason, Connect to another account offers its newest backup only when it is newer than this device's last backup (D-25); the list still shows the others. The clone check uses the same per-device `last_backup_at` (see the third case under *Cloned `device_id`*).
- **Same-platform restore only, if S1 fails.**
- **Restart failure after the old tree is gone** leaves a blank screen with no `MaterialApp`. D-20 moves the migration, the only heavy step, before that point. The next cold start opens the already-swapped file.
- **Backgrounded mid-restart.** `endOfFrame` waits until frames are enabled again, so the old database stays open while the app is in the background. If the OS kills it, the cold start finishes the restore, with no confirmation shown.
- **Re-run side effects after a restart:** a second GitHub release check and FX refresh, recurring generation, and a due check. A write already pending on the old connection at close fails with `ConnectionClosedException` and is swallowed. A write that starts after close (an FX upsert whose HTTP response arrives late) throws drift's `StateError`, which `ExchangeRateRepository`'s `on Exception` does not catch, so one uncaught async error is logged. It is harmless, and fixing it would mean changing that repository's catch, which this feature does not need.
- **One leaked `GoRouter` per restart.** `routerProvider` never disposes it. Harmless per S2; add `ref.onDispose(router.dispose)` only if S2's memory check says otherwise.
- **A cross-device restore leaves this device's previous backup behind.** D-15 gives the device a new id, so its pre-restore file keeps the old id and is never pruned by this device; it lists as another device's backup. It is the rollback path from a wrong restore, so this is intentional until the user deletes it.
- **Two "last backup" facts.** The Backup screen's line comes from the newest list row tagged `isThisDevice`; the Settings subtitle comes from `last_backup_at`, which a restore sets to the restore time and deleting this device's own file does not reset. After restoring another device's backup or deleting this device's own file, the screen can say "This device has no backup yet." while the tile shows how long ago the backup was. The two reads are intentional (the list is Drive's truth; the tile is this device's local truth), but the copy should be read with that in mind.
- **Deleting this device's own backup** does not reset `last_backup_at`, so the next automatic backup waits for the period.
- **Offline Backup screen.** The email is stored, but the account check and the list need Drive, so a connected user offline sees "Couldn't reach Google Drive." and cannot change the frequency until online. Disconnect still works offline.
- **A failure stays on screen** until the next command, because the controller is `keepAlive`. "No internet connection" can therefore describe an automatic attempt from hours ago.
- **Token expiry.** The plugin exposes no expiry. A 401 clears the token and reports `notAuthorized`; the user's retry gets a fresh token. On iOS `clearAuthorizationToken` is a no-op and the SDK refreshes on its own.
- **Shared `Dio` timeouts.** `receiveTimeout` (10 s) also covers the wait for Drive's response after the `PUT` body is sent. A slow finalisation on a poor network would show as `noNetwork`, and if Drive did store the file, it becomes a false clone (above). Add a per-request `Options(receiveTimeout:)` on the `PUT` only if that shows up.
- **Testing-status grants expire after 7 days**, so the consent screen must be In production before a release ships the feature. Without brand verification, the consent screen may not show Ledgerly's name and logo.
- **Two copies in Drive during a backup** need free space for twice the database size.
- **CI debug APKs cannot sign in** (a new debug keystore per run).
- **Android configuration errors look like a cancel.** A wrong SHA-1, package name or `serverClientId` usually surfaces as `canceled` right after the account is picked (google_sign_in_android README → Troubleshooting), and the plugin cannot tell it from a user cancel. Connect swallows it, so the button appears to do nothing. Debug APKs without a registered SHA-1, including CI's, behave this way. When Connect returns silently on a build, check the OAuth client registration first.
- **Disconnect keeps the grant.** Ledgerly stays under the account's third-party connections until the user removes it there, and other devices keep backing up (D-16); the confirm and the privacy page say so. Removing it there stops every device: each one's next command ends in `notAuthorized`, and its screen offers Reconnect and Disconnect.
- **Silent tokens name no account.** The account check (D-19) turns a token for another account into Reconnect instead of a backup to the wrong account, but it cannot fetch the right token; S3-a decides whether Android needs more. If the Google account's email changes, the check shows Reconnect once, and Reconnect stores the new email.
- **The restore offer can lose to an automatic backup.** If the app goes to the background while the offer dialog is open, and `onShow` then starts a due backup, the controller's working guard ignores the Restore tap: the dialog closes and nothing is restored. The list's Restore works once the backup ends.
- **`google_sign_in`'s pub.dev README** still says Android SDK 21+ and iOS 12+; the resolved implementations need 24 and 15, which the project meets.
- **Drift's debug-only "multiple instances" warning** prints while an older backup is migrated before staging.
